
# set locale
locale =
  city             : 'Winnipeg'
  region           : ''
  country          : ''

# set preferences
option =
  fontName         : 'Futura'
  fontSize         : 14        # scales the overall widget size
  fontColor        : '#FFF'    #
  fontColorMuted   : '#FFF'    # for RUS label; at 50% opacity
  iconSet          : 'lit'     # pixels are "lit" or "shadow" side of moon
  iconColor        : '#FFF'    # pixels
  iconBackground   : '#FFF'    #
  iconOpacity      : 0.10      # percentage (0.01-1.00); 0 is transparent
  widgetBackground : '#FFF'    #
  widgetOpacity    : 0.02      # percentage (0.01-1.00); 0 is transparent
  showPhase        : true      # the current moon phase
  showIcon         : true      #
  showCity         : true      #
  showCoords       : true      # latitude and longitude
  showAge          : true      # age in days
  showIllum        : true      # percentage illumination
  showRUS          : true      # w/separator, upcoming times for rise, upper transit, set
  showClosest      : true      # w/separator, closest phase, either ahead or behind
  showCloseDay     : true      #  +-> closest phase date, iff showClosest is true
  showAMPM         : false     # default is military time

refreshFrequency   : '1hr'     # 1hr is best accuracy for moon illumination data


# do the heavy lifting; escape spaces
command: "moon-phase.widget/get-phase.sh \"#{locale.city}\"   \
                                         \"#{locale.region}\" \
                                         \"#{locale.country}\""


style: """
  left             : 85px
  top              : 15px
  border-radius    : 20px
  padding          : 10px
  background       : rgba(#{option.widgetBackground}, #{option.widgetOpacity})
  display          : inline-block
  vertical-align   : bottom
  line-height      : 1.5

  color            : #{option.fontColor}
  font-family      : #{option.fontName}
  text-align       : center

  icon-size = #{option.fontSize * 5}px

  .error
    font-size      : #{option.fontSize}px
    color          : #FF0000
    background     : rgba(#000000, 0.5)

  .icon
    display        : inline-block
    font-family    : 'Weather'
    vertical-align : middle
    font-size      : #{option.fontSize}px
    vertical-align : middle
    text-align     : center

    fill           : #{option.iconBackground}
    width          : icon-size * 3
    height         : icon-size * 3
    max-width      : icon-size * 3
    max-height     : icon-size * 3
    border-radius  : 50%
    background     : rgba(#{option.iconBackground}, #{option.iconOpacity})

    img
      width        : 100%

    @font-face
      font-family  : 'Weather'
      src url(weather.widget/moon-icons.svg) format('svg')

  .current
    position       : relative
    display        : inline-block
    white-space    : nowrap
    text-align     : center

  .current .phase
    font-size      : #{option.fontSize * 1.7}px
    font-weight    : bold
  .current .illum
    font-size      : #{option.fontSize}px
  .current .age
    font-size      : #{option.fontSize}px

  .current .phenomenae
    display        : flex
    justify-content: space-between
  .current .phenomenae div
    color          : rgba(#{option.fontColorMuted}, 0.5)
    font-size      : #{option.fontSize * 0.75}px
    width          : 30%

  .current .phentimes
    display        : flex
    justify-content: space-between
  .current .phentimes div
    font-size      : #{option.fontSize}px
    width          : 30%

  .current .location
    font-size      : #{option.fontSize * 1.5}px

  .current .coords
    font-size      : #{option.fontSize}px

  .current .separator
    background     : #666666
    border-top     : #{option.fontSize / 10}px solid rgba(#{option.fontColor}, 0.5)
    height         : #{option.fontSize / 10}px

  .closest .clphase
    font-size      : #{option.fontSize * 0.85}px
  .closest .cldate
    font-size      : #{option.fontSize * 0.85}px

"""


option : option


render: -> """
<div class='moon'>
  <div class='current'>

    <div class='phase'></div>
    <div class='icon' #{ 'style="display:none; border-top: 0"' unless @option.showIcon }></div>
    <div class='location'></div>
    <div class='coords'></div>
    <div class='age'></div>
    <div class='illum'></div>

    <div class='separator' #{ 'style="display:none; border-top: 0"' unless @option.showRUS }></div>
    <div class='phenomenae'></div>
    <div class='phentimes'></div>

    <div class='closest'>
      <div class='separator' #{ 'style="display:none; border-top: 0"' unless @option.showClosest }></div>
      <div class='clphase'></div>
      <div class='cldate'></div>
    </div>

</div>
"""


renderMoonData: (data) ->
  moonEl = @$domEl.find('.current')

  today = new Date()

  # calculate current phase based on known new moon, modulo 29.53
  # https://en.wikipedia.org/wiki/Lunar_phase#Calculating_phase
  synodic_month = 29.530588853

  # the most recent new moon; TODO: log last new moon seen to a file?
  new_moon = new Date('03/09/2016 01:54 GMT')

  #today = new Date('03/08/2016 18:35 CST')
  #new_moon = new Date('02/08/2016 14:39 GMT')

  ms_per_day = 1000 * 60 * 60  * 24
  days_passed = (today.getTime() - new_moon.getTime()) / ms_per_day
  moon_age = days_passed % synodic_month
  moon_age = (moon_age).toFixed(1)

  if @option.showPhase
    # if moon phase isn't modulo 25, curphase is provided
    if data.curphase?
      curphase = data.curphase
    else
      curphase = data.closestphase.phase
    moonEl.find('.phase').text "#{curphase}"

# ###FIXME
  if @option.showIcon
    #icon = @getIcon(Math.floor(moon_age), @option.iconSet)
    #console.error icon
    #console.error 'Moon age:', moon_age
    #console.error 'Floored :', Math.floor(moon_age)
    moonEl.find('.icon').html @getIcon(Math.floor(moon_age), @option.iconSet)

  if @option.showCity
    moonEl.find('.location').text "#{data.city}"

  if @option.showAge
    moonEl.find('.age').text "#{moon_age} days old"

  if @option.showIllum
    # handle leading zeroes
    fracillum = Number(data.illum)
    moonEl.find('.illum').text "#{fracillum}% illumination"

  if @option.showCoords
    if data.lat > 0 then latcard = 'N' else latcard = 'S'
    if data.lon > 0 then loncard = 'E' else loncard = 'W'
    lat = Math.abs((data.lat).toFixed(2))
    lon = Math.abs((data.lon).toFixed(2))
    moonEl.find('.coords').text "#{lat}#{latcard} #{lon}#{loncard}"

  # upcoming phenomenae and times; order based on current time
  if @option.showRUS
    count = Object.keys(data.moondata).length

    phen = moonEl.find('.phenomenae')
    phen.empty()
    if count < 3
      phenName = @returnPhenomenae("#{data.prevmoondata[0].phen}")
      phen.append "<div>#{phenName}</div>"
    for d in data.moondata
      phenName = @returnPhenomenae("#{d.phen}")
      phen.append "<div>#{phenName}</div>"

    time = moonEl.find('.phentimes')
    time.empty()
    if count < 3
      if @option.showAMPM
        my_time = @returnAMPM(data.prevmoondata[0].time)
      else
        my_time = data.prevmoondata[0].time
      time.append "<div>#{my.time}</div>"
    for d in data.moondata
      if @option.showAMPM
        my_time = @returnAMPM(d.time)
      else
        my_time = d.time
      time.append "<div>#{my_time}</div>"

  if @option.showClosest
    # closest phase looks both backwards and fowards: determine which
    clday = new Date(data.closestphase.date + " " + data.closestphase.time)

    # compare in milliseconds to avoid string issues
    if clday.getTime() > today.getTime()
      clause = 'is'
    else
      clause = 'was'

    moonEl.find('.clphase').text "Closest phase #{clause} #{data.closestphase.phase}"

    if @option.showCloseDay
      # prepare time
      if @option.showAMPM
        my_time = @returnAMPM(data.closestphase.time)
      else
        my_time = data.closestphase.time
      moonEl.find('.cldate').text "on #{data.closestphase.date} at #{my_time}"


renderError: (data) ->
  moonEl = @$domEl.find('.moon')
  moonEl.find('.current').text "moon-phase: #{data.message}"
  moonEl.append "<div class='error'>moon-phase: #{data.message}</div>"


update: (output, domEl) ->
  @$domEl = $(domEl)

  data = JSON.parse(output)
  if data?.error
    console.error 'moon-phase: ', data.message
    return @renderError(data)
  @renderMoonData data


returnAMPM: (time) ->
  my_time = time.split(':')
  hh = Number(my_time[0])
  mm = Number(my_time[1])
  if hh >= 12 then time_suffix = 'PM' else time_suffix = 'AM'
  if hh > 12 then hh = hh - 12
  if mm < 10 then mm = '0' + mm
  my_time = hh + ':' + mm + ' ' + time_suffix
  return my_time


returnPhenomenae: (code) ->
  if code is "R" then return "Rises"
  if code is "U" then return "Upper Transit"
  if code is "S" then return "Sets"


getIcon: (code, iconSet) ->
  if iconSet is 'lit'
    @getLitIcon(code)
  else
    @getShadowIcon(code)

getLitIcon: (code) ->
  if code < 0 or code > 29
    return @iconLitMapping['na']
  else
    @iconLitMapping[code]

getShadowIcon: (code) ->
  if code < 0 or code > 29
    return @iconShadowMapping['na']
  else
    @iconShadowMapping[code1]

iconLitMapping:
  0  : "&#xf095;"
  1  : "&#xf096;"
  2  : "&#xf097;"
  3  : "&#xf098;"
  4  : "&#xf099;"
  5  : "&#xf09a;"
  6  : "&#xf09b;"
  7  : "&#xf09c;"
  8  : "&#xf09d;"
  9  : "&#xf09e;"
  10 : "&#xf09f;"
  11 : "&#xf0a0;"
  12 : "&#xf0a1;"
  13 : "&#xf0a2;"
  14 : "&#xf0a3;"
  15 : "&#xf0a4;"
  16 : "&#xf0a5;"
  17 : "&#xf0a6;"
  18 : "&#xf0a7;"
  19 : "&#xf0a8;"
  20 : "&#xf0a9;"
  21 : "&#xf0aa;"
  22 : "&#xf0ab;"
  23 : "&#xf0ac;"
  24 : "&#xf0ad;"
  25 : "&#xf0ae;"
  26 : "&#xf0af;"
  27 : "&#xf0b0;"
  28 : "&#xf095;"
  na : "&#xf00c;"

iconShadowMapping:
  0  : "&#xf0eb;"
  1  : "&#xf0d0;"
  2  : "&#xf0d1;"
  3  : "&#xf0d2;"
  4  : "&#xf0d3;"
  5  : "&#xf0d4;"
  6  : "&#xf0d5;"
  7  : "&#xf0d6;"
  8  : "&#xf0d7;"
  9  : "&#xf0d8;"
  10 : "&#xf0d9;"
  11 : "&#xf0da;"
  12 : "&#xf0db;"
  13 : "&#xf0dc;"
  14 : "&#xf0dd;"
  15 : "&#xf0de;"
  16 : "&#xf0df;"
  17 : "&#xf0e0;"
  18 : "&#xf0e1;"
  19 : "&#xf0e2;"
  20 : "&#xf0e3;"
  21 : "&#xf0e4;"
  22 : "&#xf0e5;"
  23 : "&#xf0e6;"
  24 : "&#xf0e7;"
  25 : "&#xf0e8;"
  26 : "&#xf0e9;"
  27 : "&#xf0ea;"
  28 : "&#xf0eb;"
  na : "&#xf00c;"

