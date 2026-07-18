import '../utils/constants.dart';

/// Builds contextual hydration reminder copy from today's progress.
class NotificationMessageBuilder {
  /// Private constructor — static helpers only.
  const NotificationMessageBuilder._();

  /// Returns a title/body pair tailored to [consumedMl] vs [goalMl].
  static ({String title, String body}) build({
    required int consumedMl,
    required int goalMl,
  }) {
    final remaining = (goalMl - consumedMl).clamp(0, goalMl);
    final progress = goalMl <= 0 ? 0.0 : consumedMl / goalMl;

    if (progress >= 1.0) {
      return (
        title: 'Great job! Keep yourself hydrated.',
        body: 'You reached today\'s goal. Sip steadily to stay refreshed.',
      );
    }

    if (remaining > 0 && remaining <= 500) {
      return (
        title: 'Only $remaining ml left to reach today\'s goal!',
        body: 'You\'re so close — finish strong with another glass.',
      );
    }

    if (progress >= 0.5) {
      return (
        title: 'You\'re halfway to today\'s goal!',
        body: 'Nice progress — keep the hydration going.',
      );
    }

    if (progress >= 0.25) {
      return (
        title: AppConstants.notificationTitle,
        body: 'You\'re building momentum. Log another glass now.',
      );
    }

    return (
      title: AppConstants.notificationTitle,
      body: AppConstants.notificationBody,
    );
  }
}
