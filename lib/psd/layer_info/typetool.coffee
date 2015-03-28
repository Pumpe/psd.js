_ = require 'lodash'
parseEngineData = require 'parse-engine-data'
LayerInfo = require '../layer_info.coffee'
Descriptor = require '../descriptor.coffee'

module.exports = class TextElements extends LayerInfo
  @shouldParse: (key) -> key is 'TySh'

  TRANSFORM_VALUE = ['xx', 'xy', 'yx', 'yy', 'tx', 'ty']
  COORDS_VALUE = ['left', 'top', 'right', 'bottom']

  constructor: (layer, length) ->
    super(layer, length)

    @version = null
    @transform = {}
    @textVersion = null
    @descriptorVersion = null
    @textData = null
    @engineData = null
    @textValue = null
    @warpVersion = null
    @descriptorVersion = null
    @warpData = null
    @coords = {}

  parse: ->
    @version = @file.readShort()

    for name, index in TRANSFORM_VALUE
      @transform[name] = @file.readDouble()

    @textVersion = @file.readShort()
    @descriptorVersion = @file.readInt()

    @textData = new Descriptor(@file).parse()
    @textValue = @textData['Txt ']
    @engineData = parseEngineData(@textData.EngineData)

    @warpVersion = @file.readShort()

    @descriptorVersion = @file.readInt()

    @warpData = new Descriptor(@file).parse()

    for name, index in COORDS_VALUE
      @coords[name] = @file.readDouble()

  fonts: ->
    return [] unless @engineData?
    @engineData.ResourceDict.FontSet.map (f) -> f.Name

  sizes: ->
    return [] if not @engineData? and not @styles().FontSize?
    _.uniq @styles().FontSize

  alignment: ->
    return [] unless @engineData?
    alignments = ['left', 'right', 'center', 'justify']
    @engineData.EngineDict.ParagraphRun.RunArray.map (s) ->
      alignments[Math.min(parseInt(s.ParagraphSheet.Properties.Justification, 10), 3)]

  styles: ->
    return {} unless @engineData?
    return @_styles if @_styles?

    data = @engineData.EngineDict.StyleRun.RunArray.map (r) ->
      r.StyleSheet.StyleSheetData

    @_styles = _.reduce(data, (m, o) ->
      for own k, v of o
        m[k] or= []
        m[k].push v
      m
    , {})
