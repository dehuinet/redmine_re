class ReRequirement < ActiveRecord::Base
  unloadable
  
  acts_as_re_artifact
  
end