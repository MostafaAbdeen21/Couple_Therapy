import '../../models/daily_journal_model.dart';

abstract class JournalState  {}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalLoaded extends JournalState {
  final List<JournalEntry> messages;
  final bool alreadySubmitted;
  final bool hasExtraJournal;

  JournalLoaded({
    required this.messages,
    required this.alreadySubmitted,
    required this.hasExtraJournal
  });

}

class JournalError extends JournalState {
  final String error;
  JournalError(this.error);
}
