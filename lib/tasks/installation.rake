namespace :installation do
  desc "Check whether an owner account exists"

  task owner_exists: :environment do
    puts User.where(role: :owner).exists?
  end

  desc "Return the current owner email"

  task owner_email: :environment do
    owner = User.where(role: :owner).first

    abort "No owner account exists." unless owner

    puts owner.email
  end

  desc "Create or update the owner account"

  task configure_owner: :environment do
    email = ENV.fetch("OWNER_EMAIL")
    password = ENV["OWNER_PASSWORD"]

    owner = User.where(role: :owner).first

    if owner
      owner.email = email

      if password.present?
        owner.password = password
        owner.password_confirmation = password
      end

      owner.save!

      puts "Owner account updated: #{owner.email}"
    else
      raise "OWNER_PASSWORD is required to create the initial owner." if password.blank?

      owner = User.new(
        email: email,
        password: password,
        password_confirmation: password,
        role: :owner
      )

      owner.save!

      puts "Owner account created: #{owner.email}"
    end
  end
end
