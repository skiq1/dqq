class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :posts

  attr_accessor :pin
  validate :correct_pin, on: :create

  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 1, maximum: 20 }

  def send_reset_password_instructions
    errors.add(:user, "can't reset the password")
    super
  end

  def self.find_for_database_authentication(conditions = {})
    find_by(username: conditions[:email]) || find_by(email: conditions[:email])
  end

  def admin?
    self.role == 1
  end

  private

  def correct_pin
    expected_pin = Rails.configuration.register_pin
    errors.add(:pin, "is incorrect") unless pin == expected_pin
  end
end
