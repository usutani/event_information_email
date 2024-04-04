class Notification < ApplicationRecord
  belongs_to :event
  belongs_to :member

  def self.create_or_update_and_notify(event:, member:)
    job_id = nil
    Notification.transaction do
      notification = Notification.transaction do
        Notification.find_or_create_by(event: event, member: member)
      end
      discard_job_by(notification.job_id)
      job_id = job_one_day_before(event.started_at).perform_later(notification).job_id
      notification.update!(job_id: job_id)
      notification
    end
  rescue
    discard_job_by(job_id)
    nil
  end

  def job
    Notification.find_job_by(job_id)
  end

  private
    def self.find_job_by(job_id)
      SolidQueue::Job.find_by(active_job_id: job_id)
    end

    def self.discard_job_by(job_id)
      find_job_by(job_id)&.discard
    end

    def self.job_one_day_before(started_at)
      NotificationJob.set(wait_until: started_at - 1.day)
    end
end
