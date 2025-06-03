abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final bool isProfileComplete;
  final bool isTherapistSelected;
  final bool hasSubscription;
  final bool hasUsedTrial;
  final bool isStartingTrial;
  final String? pairingId;

  HomeLoaded({
    required this.isProfileComplete,
    required this.isTherapistSelected,
    required this.hasSubscription,
    required this.hasUsedTrial,
    required this.isStartingTrial,
    required this.pairingId,
  });

  HomeLoaded copyWith({
    bool? isProfileComplete,
    bool? isTherapistSelected,
    bool? hasSubscription,
    bool? hasUsedTrial,
    bool? isStartingTrial,
    String? pairingId,
  }) {
    return HomeLoaded(
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isTherapistSelected: isTherapistSelected ?? this.isTherapistSelected,
      hasSubscription: hasSubscription ?? this.hasSubscription,
      hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
      isStartingTrial: isStartingTrial ?? this.isStartingTrial,
      pairingId: pairingId ?? this.pairingId,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}