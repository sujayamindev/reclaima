package com.example.mobile;

import android.content.Context;
import android.os.PowerManager;
import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import pl.leancode.patrol.PatrolJUnitRunner;

// Entry point that lets the Patrol JUnit runner discover and execute the
// Dart `patrolTest` cases under integration_test/. MainActivity extends
// FlutterActivity, so we hand it to the runner directly.
@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    // Held for the lifetime of each test so the screen stays on and the
    // device does not sleep mid-interaction on physical hardware.
    private PowerManager.WakeLock wakeLock;

    @Before
    public void acquireWakeLock() {
        Context ctx = InstrumentationRegistry.getInstrumentation().getTargetContext();
        PowerManager pm = (PowerManager) ctx.getSystemService(Context.POWER_SERVICE);
        wakeLock = pm.newWakeLock(
            PowerManager.FULL_WAKE_LOCK
                | PowerManager.ACQUIRE_CAUSES_WAKEUP
                | PowerManager.ON_AFTER_RELEASE,
            "patrol_e2e:TestWakeLock");
        wakeLock.acquire(30 * 60 * 1000L); // 30 min — enough for any single test
    }

    @After
    public void releaseWakeLock() {
        if (wakeLock != null && wakeLock.isHeld()) {
            wakeLock.release();
        }
    }

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
