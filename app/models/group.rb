class Group < ApplicationRecord

  validates_uniqueness_of :name
  validates :name, presence: true

  has_many :user_groups

end