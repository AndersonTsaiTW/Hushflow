import 'package:serverpod/serverpod.dart';
import 'dart:io';
import '../generated/protocol.dart';
import '../services/gmail_service.dart';
import '../services/ml_service.dart';

/// Summary Endpoint
/// Handles AI-generated email digest summaries
class SummaryEndpoint extends Endpoint {
  
  /// Get list of summaries
  /// Currently generates dynamic "Weekly Digests" for demonstration
  Future<List<Summary>> listSummaries(Session session, int userId) async {
    session.log('Listing summaries for user $userId');
    
    // Generate 5 mock summaries based on current date
    final now = DateTime.now();
    return List.generate(5, (index) {
      final date = now.subtract(Duration(days: index * 7));
      return Summary(
        id: index + 1, // Mock ID
        userId: userId,
        title: 'Weekly Digest #${5 - index}',
        content: 'Your weekly summary of subscription emails.',
        emailCount: 10 + (index * 2), // Mock count
        generatedAt: date,
        periodStart: date.subtract(const Duration(days: 7)),
        periodEnd: date,
        isRead: index > 0, // Mark older ones as read
      );
    });
  }

  /// Get single summary with items populated from real Gmail data
  /// This fetches recent emails and uses ML predictions for priority scores
  Future<SummaryDetails?> getSummaryDetails(Session session, String accessToken, int summaryId) async {
    session.log('Getting summary details for $summaryId');
    
    final gmail = GmailService(accessToken);
    
    // Fetch recent emails to populate the summary
    final messages = await gmail.fetchMessages(maxResults: 50);
    
    if (messages.isEmpty) {
      // Return empty summary if no emails
      final summary = Summary(
        userId: 0, 
        title: 'Weekly Email Digest',
        content: 'No emails found for this period.',
        emailCount: 0,
        generatedAt: DateTime.now(),
        periodStart: DateTime.now().subtract(const Duration(days: 7)),
        periodEnd: DateTime.now(),
        isRead: true,
      );
      return SummaryDetails(summary: summary, items: []);
    }
    
    // Prepare data for ML batch prediction
    final emailsData = <Map<String, dynamic>>[];
    final rawMessages = <Map<String, dynamic>>[];
    
    for (final msg in messages) {
      final headers = msg['headers'] as Map<String, String>;
      final subject = headers['subject'] ?? '(no subject)';
      final from = headers['from'] ?? 'unknown';
      final snippet = msg['snippet'] as String;
      final body = snippet; // Use snippet as body for now
      
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
      final linkCount = RegExp(r'https?://').allMatches(snippet).length;
      
      emailsData.add({
        'subject': subject,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'hasUnsubscribe': hasUnsubscribe,
        'linkCount': linkCount,
        'imageCount': 0,
      });
      
      rawMessages.add({
        'headers': headers,
        'snippet': snippet,
        'receivedAt': receivedAt,
      });
    }
    
    // Get ML predictions for all emails
    final mlService = MlService(
      baseUrl: Platform.environment['ML_SERVICE_URL'] ?? 'http://localhost:8000',
    );
    List<double> scores;
    try {
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
        );
      }).toList();
      
      scores = await mlService.predictBatch(
        userId: 1, // TODO: Use real userId
        featuresList: featuresList,
      );
      session.log('ML predictions complete: ${scores.length} scores');
    } catch (e) {
      session.log('ML prediction failed: $e, using default scores');
      scores = List.filled(emailsData.length, 0.5);
    }
    
    // Convert to SummaryItems with real ML scores
    final items = <SummaryItem>[];
    for (var i = 0; i < rawMessages.length; i++) {
      final msg = rawMessages[i];
      final headers = msg['headers'] as Map<String, String>;
      final subject = headers['subject'] ?? '(no subject)';
      final from = headers['from'] ?? 'unknown';
      final snippet = msg['snippet'] as String;
      final priorityScore = scores[i];
      
      items.add(SummaryItem(
        summaryId: summaryId,
        emailId: 0, // Placeholder
        sender: from.contains('<') ? from.split('<')[0].trim().replaceAll('"', '') : from,
        subject: subject,
        summaryText: snippet.length > 150 ? '${snippet.substring(0, 150)}...' : snippet,
        priorityScore: priorityScore,
        order: i,
      ));
    }
    
    // Create the parent summary object
    final summary = Summary(
      userId: 0, 
      title: 'Weekly Email Digest',
      content: 'AI-curated summary of your ${items.length} most important subscription emails.',
      emailCount: items.length,
      generatedAt: DateTime.now(),
      periodStart: DateTime.now().subtract(const Duration(days: 7)),
      periodEnd: DateTime.now(),
      isRead: false,
    );

    session.log('Generated summary with ${items.length} items');
    return SummaryDetails(summary: summary, items: items);
  }
}
