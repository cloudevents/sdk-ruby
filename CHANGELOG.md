# Changelog

### v0.5.0 / 2021-06-28

* BREAKING CHANGE: Properly handle data when the content-type indicates JSON 
* BREAKING CHANGE: Decode returns opaque event objects when a formatter is not available 

* ADDED: Decode returns opaque event objects when a formatter is not available 
* FIXED: Properly handle data when the content-type indicates JSON 
* FIXED: Set application/json by default when using json structured format 
* DOCS: A number of documentation fixes 

### v0.4.0 / 2021-05-26

* ADDED: ContentType can take an optional default charset 
* FIXED: Binary HTTP format parses quoted tokens according to RFC 7230 section 3.2.6 
* FIXED: When encoding structured events for HTTP transport, the content-type now includes the charset

### v0.3.1 / 2021-04-25

* FIXED: Fixed exception when decoding from a rack source that uses InputWrapper 
* FIXED: Fixed equality checking for V0 events 

### v0.3.0 / 2021-03-02

* ADDED: Require Ruby 2.5 or later
* FIXED: Deep-duplicated event attributes in to_h to avoid returning frozen objects 

### v0.2.0 / 2021-01-25

* ADDED: Freeze event objects to make them Ractor-shareable
* DOCS: Fix formatting of Apache license 

### v0.1.2 / 2020-09-02

* Fix: Convert extension attributes to strings, and ignore nils 
* Documentation: Add code of conduct link to readme

### v0.1.1 / 2020-07-20

* Updated a few documentation links. No functional changes.

### v0.1.0 / 2020-07-08

* Initial release of the Ruby SDK.
