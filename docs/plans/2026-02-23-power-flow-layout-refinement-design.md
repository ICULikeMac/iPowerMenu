# Power Flow Layout Refinement Design

## Goals
- Remove Car from circle graph in both full and compact views.
- Show Car only in the text/list section.
- Draw dotted connector lines between visible circles.
- Prevent dots from entering/overlapping circle boundaries.

## Decisions
- Keep Car in flow math as a source/sink, but do not render a Car node.
- Render only Solar, Grid, Battery, Home circles in graph.
- Add subtle dashed connector lines behind animated dots.
- Increase endpoint clearance (radius padding) in both views.

## Validation
- Unit test that visible node routes exist and car-node routes are not renderable.
- Run full test suite.
- Manual visual check in full and compact views.
