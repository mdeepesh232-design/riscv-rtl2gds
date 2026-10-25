read_liberty /OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib
read_db ./results/nangate45/riscv_core/base/2_4_floorplan_pdn.odb

set block [ord::get_db_block]
set die [$block getDieArea]
set x1 [expr {[$die xMin] / 2000.0}]
set y1 [expr {[$die yMin] / 2000.0}]
set x2 [expr {[$die xMax] / 2000.0}]
set y2 [expr {[$die yMax] / 2000.0}]

gui::save_image pdn.png $x1 $y1 $x2 $y2 1200
