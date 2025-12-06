# Verification Plan Table — controller_cdl (CDL controller)

## Criteria Definitions
- 1: FSM transitions follow stimulus (store/load/start) and sram_state handshake.
- 2: weight counter increments on sram_state==2 with weight read/write enable.
- 3: Busy signalling: buffer_busy and design_busy reflect controller activity.
- 4: Weights_loaded/data_ready pulses produced at correct points.
- 5: Output path: systolic_out reflects sram_data presented at DONE.
- 6: Byte lane selection in Operate_D1..D8 maps to in_bus byte positions.
- 7: Control signals (read_w_enable/read_in_enable/write_* etc.) assert per state.
- 8: Reset behaviour: FSM and weight counter reset to IDLE/0.
- 9: Safe default behaviour in IDLE.

## Verification Plan Table

Module Tested | Feature Tested | Test Name | Criteria Number | Description of Test Inputs | Description of Expected Outputs
--- | --- | --- | --- | --- | ---
`controller_cdl` | Reset behaviour | Reset initializes FSM and counters | 8 | Hold n_rst low for multiple cycles then release. | current_state==IDLE and weight_num==0.
`controller_cdl` | Store weights | Store Weights pulse | 1,2,7 | Pulse store_weights with weights value and emulate sram_state==2. | write_w_enable asserted during LOAD_weight; data driven = weights; weight counter increments when sram_state==2 and write_w_enable active.
`controller_cdl` | Store inputs | Store Inputs pulse | 1,7 | Pulse store_inputs with inputs value and emulate sram_state==2. | write_in_enable asserted during LOAD_input; data driven = inputs.
`controller_cdl` | Load weights sequence | load_weights then 8 sram beats | 1,2,4,6,7 | Assert load_weights then present 8 beats with sram_state==2 and distinct sram_data. | read_w_enable asserted each LOAD_C*; in_bus samples sram_data each beat; after 8 beats FSM enters Weights_loaded then IDLE; weights_loaded asserted.
`controller_cdl` | Start inference flow | start_inference through DONE | 1,3,4,5,6 | Assert start_inference; provide sram_state==2 at Read_i1 and at Store_out; provide sram_data with known pattern. | read_in_enable at Read_i1; Operate_D1..D8 assert operate_f and in_bus bytes map correctly; after waits and Store_out->DONE, data_ready asserted and systolic_out equals sram_data presented at DONE.
`controller_cdl` | Byte mapping | Operate_Dn -> in_bus slice | 6 | During Operate_D1..D8 present sram_data bytes = 0x00..0x07 pattern. | in_bus[7:0]==byte0 at D1, in_bus[15:8]==byte1 at D2, ... in_bus[63:56]==byte7 at D8.
`controller_cdl` | Weight counter rollover | counter wraps from 7->0 | 2 | Provide 8 consecutive sram_state==2 beats while read_w_enable/write_w_enable active. | weight_num increments each beat and wraps to 0 after 7.
`controller_cdl` | Busy flags | buffer_busy/design_busy assert during ops | 3 | Trigger LOAD_* and Operate sequences. | buffer_busy asserted during LOAD/Read; design_busy asserted during operate and wait states.
`controller_cdl` | Weights_loaded pulse | indication after load | 4 | Complete 8 LOAD_C beats. | weights_loaded asserted in Weights_loaded state.
`controller_cdl` | Data ready & output | DONE -> systolic_out | 4,5 | Drive sram_data and force Store_out->DONE via sram_state==2. | data_ready asserted and systolic_out == sram_data at DONE.
`controller_cdl` | Default outputs | IDLE defaults | 9 | Remain in IDLE with no inputs asserted. | outputs are default/zero except weight_num reflecting counter.
`controller_cdl` | Smoke test | end-to-end sequence | 1..7 | store_weights, store_inputs, load_weights (8 beats), start_inference, complete | Full flow completes; weights_loaded/data_ready asserted at expected times; counters and enables behave per spec.