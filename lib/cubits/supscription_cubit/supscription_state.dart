abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}
class SubscriptionLoading extends SubscriptionState {}
class SubscriptionSuccess extends SubscriptionState {
  final String url;
  final String pairingId;
  SubscriptionSuccess({required this.url, required this.pairingId});
}
class SubscriptionConfirmed extends SubscriptionState {}
class SubscriptionError extends SubscriptionState {
  final String message;
  SubscriptionError(this.message);
}
