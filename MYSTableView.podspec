Pod::Spec.new do |s|
  s.name         = "MYSTableView"
  s.version      = "0.0.1"
  s.summary      = "A wrapper around NSTableView."
  s.homepage     = "https://github.com/mysterioustrousers/MYSTableView"
  s.license      = "MIT"
  s.author             = { "Adam Kirk" => "atomkirk@gmail.com" }
  s.social_media_url   = "http://twitter.com/atomkirk"
  s.platform     = :osx
  s.source       = { :git => "https://github.com/mysterioustrousers/MYSTableView", :tag => "0.0.1" }
  s.source_files  = "*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.requires_arc = true
end
