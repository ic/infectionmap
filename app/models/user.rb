class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
         :confirmable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable
end
