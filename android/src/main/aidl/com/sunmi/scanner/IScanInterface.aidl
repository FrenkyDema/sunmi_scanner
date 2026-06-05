package com.sunmi.scanner;

interface IScanInterface {
    /**
     * key.getAction()==KeyEvent.ACTION_UP
     * key.getAction()==KeyEvent.ACTION_DWON
     */
    void sendKeyEvent(in KeyEvent key);
    /**
     * Trigger start scan
     */
    void scan();
    /**
     * Trigger stop scan
     */
    void stop();
    /**
     * Get scanner head type:
     * 100: NONE
     * 101: super_n1365_y1825
     * 102: newland-2096
     * 103: zebra-4710
     * 104: honeywell-3601
     * 105: honeywell-6603
     * 106: zebra-4750
     * 107: zebra-1350
     * 108: honeywell-6703
     * 109: honeywell-3603
     * 110: newland-cm47
     * 111: newland-3108
     * 112: zebra_965
     * 113: sm_ss_1100
     * 114: newland-cm30
     * 115: honeywell-4603
     * 116: zebra_4770
     * 117: newland_2596
     * 118: sm_ss_1103
     * 119: sm_ss_1101
     * 120: honeywell_5703
     * 121: sm_ss_1100_2
     * 122: sm_ss_1104
     */
    int getScannerModel();
    /**
     * Set scanner head type (use with caution — wrong value may disable scanner service until cache cleared)
     */
    void setScannerModel(in int Model);
    /**
     * Send command to scanner
     */
    void sendCommand(in String cmd);
}
