# == Schema Information
#
# Table name: characters
#
#  id          :bigint           not null, primary key
#  description :string
#  image       :string
#  name        :string           not null
#
# Indexes
#
#  index_characters_on_image  (image)
#
class Character < ApplicationRecord
  has_many :character_images
  has_many :character_animations
  has_many :animations, through: :character_animations
  has_many :images, through: :character_images

  accepts_nested_attributes_for :character_animations, allow_destroy: true
  accepts_nested_attributes_for :animations, allow_destroy: true
  mount_uploader :image, ImageUploader

  validates :name, presence: true
end
