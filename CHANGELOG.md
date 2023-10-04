# Changelog

### v0.7.1 / 2023-10-04

* DOCS: Governance docs per CE PR 1226

### v0.7.0 / 2022-01-14

* HttpBinding#probable_event? returns false if the request method is GET or HEAD.
* HttpBinding#decode_event raises NotCloudEventError if the request method is GET or HEAD. 
* Fixed a NoMethodError if nil content was passed to the ContentType constructor.

### v0.6.0 / 2021-08-23

This update further clarifies and cleans up the encoding behavior of event payloads. In particular, the event object now includes explicitly encoded data in the new `data_encoded` field, and provides information on whether the existing `data` field contains an encoded or decoded form of the payload.

* Added `data_encoded`, `data_decoded?` and `data?` methods to `CloudEvents::Event::V1`, added `:data_encoded` as an input attribute, and clarified the encoding semantics of each field.
* Changed `:attributes` keyword argument in event constructors to `:set_attributes`, to avoid any possible collision with a real extension attribute name. (The old argument name is deprecated and will be removed in 1.0.)
* Fixed various inconsistencies in the data encoding behavior of `JsonFormat` and `HttpBinding`.
* Support passing a data content encoder/decoder into `JsonFormat#encode_event` and `JsonFormat#decode_event`.
* Provided `TextFormat` to handle media types with trivial encoding.
* Provided `Format::Multi` to handle checking a series of encoders/decoders.

### v0.5.1 / 2021-06-28

* ADDED: Add HttpBinding#probable_event? 
* FIXED: Fixed a NoMethodError when a format declined to decode an http request 

### v0.5.0 / 2021-06-28

This is a significant update that provides several important spec-related and usability fixes. Some of the behavioral changes are breaking, so to preserve compatibility, new methods were added and old methods deprecated, particularly in the HttpBinding class. Additionally, the formatter interface has been simplified and expanded to support payload formatting.

* CHANGED: Deprecated HttpBinding#decode_rack_env and replaced with HttpBinding#decode_event. (The old method remains for backward compatibility, but will be removed in version 1.0). The new decode_event method has the following differences:
    * decode_event raises NotCloudEventError (rather than returning nil) if given an HTTP request that does not seem to have been intended as a CloudEvent.
    * decode_event takes an allow_opaque argument that, when set to true, returns a CloudEvents::Event::Opaque (rather than raising an exception) if given a structured event with a format not known by the SDK. Opaque event objects cannot have their fields inspected, but can be reserialized for retransmission to another event handler.
    * decode_event in binary content mode now parses JSON content-types and exposes the data attribute as a JSON value.
* CHANGED: Deprecated the HttpBinding encoding entrypoints (encode_structured_content, encode_batched_content, and encode_binary_content) and replaced with a single encode_event entrypoint that handles all cases via the structured_format argument. (The old methods remain for backward compatibility, but will be removed in version 1.0). In addition, the new encode_event method has the following differences:
    * encode_event in binary content mode now interprets a string-valued data attribute as a JSON string and serializes it (i.e. wraps it in quotes) if the data_content_type has a JSON format. This is for compatibility with the behavior of the JSON structured mode which always treats the data attribute as a JSON value if the data_content_type indicates JSON.
* CHANGED: The JsonFormat class interface was reworked to be more generic, combine the structured and batched calls, and add calls to handle data payloads. A Format module has been added to specify the interface used by JsonFormat and future formatters. (Breaking change of internal interfaces)
* CHANGED: Renamed HttpContentError to UnsupportedFormatError to better reflect the specific issue being reported, and to eliminate the coupling to http. The old name remains aliased to the new name, but is deprecated and will be removed in version 1.0.
* CHANGED: If format-driven parsing (e.g. parsing a JSON document) fails, a FormatSyntaxError will be raised instead of, for example, a JSON-specific error. The lower-level parser error can still be accessed from the exception's "cause".
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
