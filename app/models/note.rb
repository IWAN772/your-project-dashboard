# frozen_string_literal: true

class Note < ApplicationRecord
  belongs_to :project

  validates :content, presence: true

  # Most recent notes first
  default_scope -> { order(created_at: :desc) }
end
