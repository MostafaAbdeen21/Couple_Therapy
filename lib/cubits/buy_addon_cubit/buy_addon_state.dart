abstract class BuyAddonState {}

class BuyAddonInitial extends BuyAddonState {}

class BuyAddonLoading extends BuyAddonState {}

class BuyAddonSuccess extends BuyAddonState {
  final String url;
  BuyAddonSuccess(this.url);
}

class BuyAddonError extends BuyAddonState {
  final String message;
  BuyAddonError(this.message);
}
