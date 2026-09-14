package com.legendstudy.app

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle

/** Public configuration surface required for a rule without ConditionProviderService. */
class StudyFocusSettingsActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AlertDialog.Builder(this)
            .setTitle("레전드스터디 집중 설정")
            .setMessage("앱의 학습 > 집중 설정에서 시작 시 연동 여부를 선택할 수 있어요. 일시정지 중에는 유지되고 공부 종료 시 앱이 요청한 상태만 해제해요. 기기의 다른 알림 설정은 그대로 유지돼요. 앱을 강제로 종료한 뒤에는 기기의 방해 금지 상태를 확인해 주세요.")
            .setPositiveButton("앱 열기") { _, _ ->
                startActivity(Intent(this, MainActivity::class.java)); finish()
            }
            .setNegativeButton("닫기") { _, _ -> finish() }
            .setOnCancelListener { finish() }
            .show()
    }
}
