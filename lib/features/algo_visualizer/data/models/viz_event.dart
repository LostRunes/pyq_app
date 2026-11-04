sealed class VizEvent {
  const VizEvent({this.text, this.line});
  final String? text;
  final int? line;
}

final class CompareEvent extends VizEvent {
  const CompareEvent(this.indices, {super.text, super.line});
  final List<int> indices;
}

final class SwapEvent extends VizEvent {
  const SwapEvent(this.indices, {super.text, super.line});
  final List<int> indices;
}

final class OverwriteEvent extends VizEvent {
  const OverwriteEvent(this.index, this.value, {super.text, super.line});
  final int index;
  final int value;
}

final class MarkSortedEvent extends VizEvent {
  const MarkSortedEvent(this.indices, {super.text, super.line});
  final List<int> indices;
}

final class PivotEvent extends VizEvent {
  const PivotEvent(this.index, {super.text, super.line});
  final int index;
}

final class RangeEvent extends VizEvent {
  const RangeEvent(this.start, this.end, {super.text, super.line});
  final int start;
  final int end;
}

final class PointersEvent extends VizEvent {
  const PointersEvent({
    this.left,
    this.right,
    this.mid,
    this.boundary,
    super.text,
    super.line,
  });
  final int? left;
  final int? right;
  final int? mid;
  final int? boundary;
}

final class EnqueueEvent extends VizEvent {
  const EnqueueEvent(this.node, {super.text, super.line});
  final int node;
}

final class DequeueEvent extends VizEvent {
  const DequeueEvent(this.node, {super.text, super.line});
  final int node;
}

final class VisitEvent extends VizEvent {
  const VisitEvent(this.node, {super.text, super.line});
  final int node;
}

final class RelaxEvent extends VizEvent {
  const RelaxEvent(this.from, this.to, {super.text, super.line});
  final int from;
  final int to;
}

final class DistanceEvent extends VizEvent {
  const DistanceEvent(this.node, this.distance, {super.text, super.line});
  final int node;
  final double distance;
}

final class MessageEvent extends VizEvent {
  const MessageEvent(String text, {super.line}) : super(text: text);
}

final class BucketEvent extends VizEvent {
  const BucketEvent(this.bucketIndex, this.values, {super.text, super.line});
  final int bucketIndex;
  final List<int> values;
}

final class DigitEvent extends VizEvent {
  const DigitEvent(this.digit, this.place, {super.text, super.line});
  final int digit;
  final int place;
}

enum VizNodeState { hidden, discovered, current, settled }