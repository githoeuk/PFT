package com.paintfieldtracker.pft;

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(BackupDocumentsPlugin.class);
        super.onCreate(savedInstanceState);
    }
}
