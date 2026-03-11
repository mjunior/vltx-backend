namespace :admin do
  desc "Create or reconcile an admin via ADMIN_EMAIL and ADMIN_PASSWORD"
  task create: :environment do
    email = ENV["ADMIN_EMAIL"].to_s.strip.downcase
    password = ENV["ADMIN_PASSWORD"].to_s
    active = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ADMIN_ACTIVE", "true"))
    reset_password = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ADMIN_RESET_PASSWORD", "false"))

    abort "Missing ADMIN_EMAIL" if email.blank?
    abort "Missing ADMIN_PASSWORD" if password.blank?

    admin = Admin.find_by(email: email)

    if admin.nil?
      admin = Admin.new(
        email: email,
        password: password,
        password_confirmation: password,
        active: active
      )

      begin
        admin.save!
        puts "Admin created: #{admin.email} active=#{admin.active}"
        next
      rescue ActiveRecord::RecordNotUnique
        admin = Admin.find_by!(email: email)
      end
    end

    changed = false

    if admin.active != active
      admin.active = active
      changed = true
    end

    if reset_password
      admin.password = password
      admin.password_confirmation = password
      changed = true
    end

    if changed
      admin.save!
      puts "Admin updated: #{admin.email} active=#{admin.active} password_reset=#{reset_password}"
    else
      puts "Admin already exists: #{admin.email} active=#{admin.active} password_reset=false"
    end
  end
end
