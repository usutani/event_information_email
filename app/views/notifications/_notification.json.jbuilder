json.extract! notification, :id, :job_id, :event_id, :member_id, :created_at, :updated_at
json.url notification_url(notification, format: :json)
