package com.paintfieldtracker.pft;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import androidx.activity.result.ActivityResult;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

@CapacitorPlugin(name = "BackupDocuments")
public class BackupDocumentsPlugin extends Plugin {
    private volatile boolean saving = false;

    @PluginMethod
    public void save(PluginCall call) {
        String fileName = call.getString("fileName");
        String contents = call.getString("contents");
        if (fileName == null || fileName.isEmpty() || contents == null) {
            call.reject("A file name and contents are required.", "INVALID_ARGUMENT");
            return;
        }
        if (saving) {
            call.reject("A backup save is already in progress.", "SAVE_IN_PROGRESS");
            return;
        }

        saving = true;
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("application/json");
        intent.putExtra(Intent.EXTRA_TITLE, fileName);

        try {
            startActivityForResult(call, intent, "documentCreated");
        } catch (ActivityNotFoundException error) {
            saving = false;
            call.reject("No document picker is available.", "PICKER_UNAVAILABLE");
        } catch (RuntimeException error) {
            saving = false;
            call.reject("Unable to open the document picker.", "PICKER_FAILED");
        }
    }

    @ActivityCallback
    private void documentCreated(PluginCall call, ActivityResult result) {
        if (call == null) {
            saving = false;
            return;
        }
        if (result.getResultCode() == Activity.RESULT_CANCELED) {
            saving = false;
            call.resolve(new JSObject().put("cancelled", true));
            return;
        }

        Intent data = result.getData();
        Uri uri = data != null ? data.getData() : null;
        if (result.getResultCode() != Activity.RESULT_OK || uri == null) {
            saving = false;
            call.reject("The document picker did not return a file.", "INVALID_DOCUMENT");
            return;
        }

        // Document providers may perform slow disk or network writes.
        execute(() -> {
            try {
                String contents = call.getString("contents");
                if (contents == null) throw new IOException("Backup contents are unavailable.");
                try (OutputStream output = getContext().getContentResolver().openOutputStream(uri, "w")) {
                    if (output == null) throw new IOException("Unable to open the document.");
                    output.write(contents.getBytes(StandardCharsets.UTF_8));
                }
                saving = false;
                call.resolve(new JSObject().put("cancelled", false));
            } catch (IOException | RuntimeException error) {
                saving = false;
                call.reject("Unable to write the backup file.", "WRITE_FAILED");
            }
        });
    }
}
