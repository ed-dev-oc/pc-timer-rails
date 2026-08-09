class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :registerable, :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  enum :role, [ :user, :admin, :owner ]

  validate :only_one_owner_exist!, on: :create

  private
    def only_one_owner_exist!
      if User.owner.present? && self.owner?
        errors.add(:base, "Owner already exist!")
      end
    end
end
