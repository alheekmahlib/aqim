/// Stage 4 adapter stops both owners of the current adhan, but not previews or
/// future alarms. Calling stop more than once must be safe.
abstract interface class AdhanPlaybackControl {
  Future<void> stopCurrentAdhan();
}
