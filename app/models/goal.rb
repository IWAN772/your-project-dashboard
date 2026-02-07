class Goal < ApplicationRecord
  has_many :project_goals, dependent: :destroy
  has_many :projects, through: :project_goals

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.to_s.strip.downcase if name.present?
  end
end
