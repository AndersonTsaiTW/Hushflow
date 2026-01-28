import 'package:serverpod/serverpod.dart';
import '../services/ml_service.dart';
import '../services/gmail_service.dart';
import '../generated/sender_priority.dart';

/// ML Endpoint
/// Provides email priority predictions using the Python ML service
class MlEndpoint extends Endpoint {
  final _mlService = MlService();
  
  /// Get priority score for a single email
  Future<double> predictPriority(
    Session session,
    int userId,
    String subject,
    String body,
    DateTime receivedAt,
    bool hasUnsubscribe,
    int linkCount,
    int imageCount,
  ) async {
    session.log('Predicting priority for email: ${subject.substring(0, subject.length.clamp(0, 50))}...');
    
    final features = MlService.extractFeatures(
      subject: subject,
      body: body,
      receivedAt: receivedAt,
      hasUnsubscribe: hasUnsubscribe,
      linkCount: linkCount,
      imageCount: imageCount,
    );
    
    try {
      final score = await _mlService.predictPriority(
        userId: userId,
        features: features,
      );
      session.log('Priority score: $score');
      return score;
    } catch (e) {
      session.log('ML prediction failed: $e, using default score');
      return 0.5; // Default score on error
    }
  }
  
  /// Get priority scores for multiple emails (batch)
  /// Each email should be a map with: subject, body, receivedAt, hasUnsubscribe, linkCount, imageCount
  Future<List<double>> predictBatch(
    Session session,
    int userId,
    List<Map<String, dynamic>> emailsData,
  ) async {
    session.log('Batch predicting ${emailsData.length} emails');
    
    final featuresList = emailsData.map((email) {
      final receivedAtStr = email['receivedAt'];
      DateTime receivedAt;
      if (receivedAtStr is DateTime) {
        receivedAt = receivedAtStr;
      } else if (receivedAtStr is String) {
        receivedAt = DateTime.tryParse(receivedAtStr) ?? DateTime.now();
      } else {
        receivedAt = DateTime.now();
      }
      
      return MlService.extractFeatures(
        subject: email['subject'] as String? ?? '',
        body: email['body'] as String? ?? '',
        receivedAt: receivedAt,
        hasUnsubscribe: email['hasUnsubscribe'] as bool? ?? false,
        linkCount: email['linkCount'] as int? ?? 0,
        imageCount: email['imageCount'] as int? ?? 0,
        senderOpenRate: (email['senderOpenRate'] as num?)?.toDouble() ?? 0.5,
        senderFrequency: email['senderFrequency'] as int? ?? 1,
      );
    }).toList();
    
    try {
      final scores = await _mlService.predictBatch(
        userId: userId,
        featuresList: featuresList,
      );
      session.log('Batch prediction complete: ${scores.length} scores');
      return scores;
    } catch (e) {
      session.log('Batch ML prediction failed: $e');
      return List.filled(emailsData.length, 0.5);
    }
  }
  /// Analyze inbox and group by sender with priority scores
  Future<List<SenderPriority>> analyzeInbox(
    Session session,
    String accessToken,
    int userId, {
    int maxEmails = 50,  // Scan 50 emails for faster performance
  }) async {
    session.log('Analyzing inbox for user $userId');
    
    final gmail = GmailService(accessToken);
    
    // Fetch recent emails
    final messages = await gmail.fetchMessages(maxResults: maxEmails);
    
    if (messages.isEmpty) {
      return [];
    }
    
    // 1. Extract features and prepare for prediction
    final featuresList = <Map<String, dynamic>>[];
    final emailInfos = <Map<String, dynamic>>[];
    
    for (final msg in messages) {
      final headers = msg['headers'] as Map<String, String>? ?? {};
      final subject = headers['subject'] ?? '(no subject)';
      final from = headers['from'] ?? 'unknown';
      final body = msg['snippet'] as String? ?? '';
      
      final labelIds = (msg['labelIds'] as List<dynamic>?)?.cast<String>() ?? [];
      final isRead = !labelIds.contains('UNREAD');
      
      final dateStr = headers['date'];
      DateTime receivedAt;
      try {
        receivedAt = dateStr != null 
          ? DateTime.tryParse(dateStr) ?? DateTime.now()
          : DateTime.now();
      } catch (e) {
        receivedAt = DateTime.now();
      }
      
      final hasUnsubscribe = headers.containsKey('list-unsubscribe');
      
      featuresList.add(MlService.extractFeatures(
        subject: subject,
        body: body,
        receivedAt: receivedAt,
        hasUnsubscribe: hasUnsubscribe,
        linkCount: RegExp(r'https?://').allMatches(body).length,
        imageCount: 0,
      ));
      
      emailInfos.add({
        'id': msg['id'],
        'subject': subject,
        'from': from,
        'receivedAt': receivedAt,
        'snippet': body.length > 100 ? '${body.substring(0, 100)}...' : body,
        'hasUnsubscribe': hasUnsubscribe,
        'isRead': isRead,
      });
    }
    
    // 2. Get predictions
    List<double> scores;
    try {
      scores = await _mlService.predictBatch(
        userId: userId,
        featuresList: featuresList,
      );
    } catch (e) {
      session.log('Batch prediction failed: $e');
      scores = List.filled(emailInfos.length, 0.5);
    }
    
    // 3. Group by Sender
    final senderGroups = <String, SenderPriority>{};
    
    for (var i = 0; i < emailInfos.length; i++) {
        final info = emailInfos[i];
        final score = scores[i];
        final rawFrom = info['from'] as String;
        
        // Extract email address for grouping
        final emailMatch = RegExp(r'<([^>]+)>').firstMatch(rawFrom);
        final email = emailMatch != null ? emailMatch.group(1)!.toLowerCase() : rawFrom.trim().toLowerCase();
        
        final currentPriority = senderGroups[email];
        
        if (currentPriority == null) {
          senderGroups[email] = SenderPriority(
            email: email,
            name: rawFrom.contains('<') ? rawFrom.split('<')[0].trim().replaceAll('"', '') : rawFrom,
            maxScore: score,
            latestSnippet: info['snippet'],
            latestReceivedAt: info['receivedAt'],
            emailCount: 1,
            isWhitelisted: false, // Default
          );
        } else {
            // Update if this email has higher score or is newer
            // Use MAX score logic as requested
            if (score > currentPriority.maxScore) {
                currentPriority.maxScore = score;
            }
            
            // Update snippet if newer
            if ((info['receivedAt'] as DateTime).isAfter(currentPriority.latestReceivedAt)) {
                currentPriority.latestReceivedAt = info['receivedAt'];
                currentPriority.latestSnippet = info['snippet'];
            }
            
            currentPriority.emailCount++;
        }
    }
    
    final results = senderGroups.values.toList();
    
    // Sort by max priority (highest first)
    results.sort((a, b) => b.maxScore.compareTo(a.maxScore));
    
    session.log('Analyzed ${results.length} senders from ${emailInfos.length} emails');
    
    return results;
  }
}
