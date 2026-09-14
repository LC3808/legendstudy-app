package com.legendstudy.app
import org.junit.Assert.*
import org.junit.Test
class FocusLeasePolicyTest {
    @Test fun runningAndPausedSameSessionRetainLease() {
        assertTrue(FocusLeasePolicy.retain("A", "A", 86400000, 1000))
        assertTrue(FocusLeasePolicy.retain("A", "A", 86400000, 3000))
    }
    @Test fun endAccountSwitchAndExpiredDraftNeverRetain() {
        assertFalse(FocusLeasePolicy.retain("A", null, 86400000, 1000))
        assertFalse(FocusLeasePolicy.retain("A", "B", 86400000, 1000))
        assertFalse(FocusLeasePolicy.retain("A", "A", 86400000, 86400000))
    }
}
