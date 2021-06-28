# Changelog

### v0.5.0 / 2021-06-28

This is a significant update that reworks the interface of the JSON formatter and applies fixes to of its payload encoding behavior. There are several breaking changes to internal interfaces, as well as breaking fixes to the encoding/decoding behavior of HttpBinding class, and a few deprecations.

* FIXED: HttpBinding#decode_rack_env in binary content mode now parses JSON content-types and exposes the data attribute as a JSON value. Similarly, encoding in binary content mode serializes a JSON document even if the payload is string-typed. (BREAKING CHANGE)
* CHANGED: HttpBinding#decode_rack_env raises CloudEvents::NotCloudEventError (rather than returning nil) if given an HTTP request that does not seem to have been intended as a CloudEvent. (BREAKING CHANGE)
* CHANGED: The JsonFormat class interface was reworked to be more generic, combine the structured and batched calls, and add calls to handle data payloads. A Format module has been added to specify the interface used by JsonFormat and future formatters. (Breaking change of internal interfaces)
* ADDED: It is now possible to tell HttpBinding#decode_rack_env to return an opaque object if the request specifies a format that is not known by the SDK. This opaque object cannot have its fields inspected, but can be reserialized for retransmission to another event handler.
* CHANGED: If opaque objects are disabled and an input request has an unknown format, HttpBinding#decode_rack_env now raises UnsupportedFormatError instead of HttpContentError. (The old exception name is aliased to the new name for backward compatibility, but is deprecated and will be removed in version 1.0.)
* CHANGED: If format-driven parsing fails, HttpBinding#decode_rack_env will raise FormatSyntaxError instead of, for example, a JSON-specific error. The lower-level parser error can still be accessed as the "cause".
* CHANGED: Consolidated HttpBinding encoding entrypoints into one HttpBinding#encode_event call. The older encode_structured_content, encode_batched_content, and encode_binary_content calls are now deprecated.
* FIXED: JsonFormat now sets the datacontenttype attribute explicitly to "application/json" if it isn't otherwise set.

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
