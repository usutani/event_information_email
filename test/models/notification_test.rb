require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "Create - create_or_update_and_notify" do
    started_at = Time.current.since(1.week)
    event = Event.create! name: "イベント1", started_at: started_at
    member = Member.create! email: "member1@example.com"

    assert_difference "Notification.count" do "Notificationは1件だけ生成されること"
      assert_difference "SolidQueue::Job.count" do "SolidQueue::Jobは1件だけ生成されること"
        notification = Notification.create_or_update_and_notify(event: event, member: member)
        assert notification, "生成に成功すること"
        notifications = Notification.where(event: event, member: member)
        assert_equal notification.event, event, "イベントは一致すること"
        assert_equal notification.member, member, "メンバーは一致すること"
        assert_in_delta started_at - 1.day, notification.job.scheduled_at, 1, "ジョブの開始は開始日時の1日前（誤差1秒）"
      end
    end
  end

  test "Update - create_or_update_and_notify" do
    started_at_old = Time.current.since(1.week)
    event = Event.create! name: "イベント1", started_at: started_at_old
    member = Member.create! email: "member1@example.com"
    Notification.create_or_update_and_notify(event: event, member: member)

    # イベントの開始日時を変更する
    started_at_new = Time.current
    event.update! started_at: started_at_new

    assert_no_difference "Notification.count" do "Notificationの件数は変わらないこと"
      assert_no_difference "SolidQueue::Job.count" do "SolidQueue::Jobの件数は変わらないこと"
        notification = Notification.create_or_update_and_notify(event: event, member: member)
        assert notification, "更新に成功すること"
        notifications = Notification.where(event: event, member: member)
        assert_equal notification.event, event, "イベントは一致すること"
        assert_equal notification.member, member, "メンバーは一致すること"
        assert_in_delta started_at_new - 1.day, notification.job.scheduled_at, 1, "ジョブの開始は変更した開始日時の1日前（誤差1秒）"
      end
    end
  end

  test "job" do
    started_at = Time.current.since(1.week)
    event = Event.create! name: "イベント1", started_at: started_at
    member = Member.create! email: "member1@example.com"

    assert_difference "Notification.count" do "Notificationは1件だけ生成されること"
      assert_difference "SolidQueue::Job.count" do "SolidQueue::Jobは1件だけ生成されること"
        Notification.create_or_update_and_notify(event: event, member: member)
        assert job_id = Notification.find_by(event: event, member: member).job_id, "ジョブIDが設定されていること"
        assert job = SolidQueue::Job.find_by(active_job_id: job_id), "ジョブが生成されていること"
        assert_in_delta started_at - 1.day, job.scheduled_at, 1, "ジョブの開始は開始日時の1日前（誤差1秒）"
      end
    end
  end
end
