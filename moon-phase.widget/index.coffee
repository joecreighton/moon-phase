
# set locale
locale =
  city              : ''
  region            : ''


# set preferences
option =
  fontName          : 'Futura'
  fontSize          : 14        # scales the overall widget size
  fontColor         : '#FFF'    #
  fontColorMuted    : '#FFF'    # for RUS label; at 50% opacity

  iconSet           : 'lit'     # pixels to be 'lit' or 'shadow' side of moon
  iconColor         : '#FFF'    #

  widgetBackground  : '#FFF'    #
  widgetOpacity     : 0.00      # percentage (0.01-1.00); 0 is transparent

  showCity          : true      #
  showCoords        : true      # latitude and longitude
  showAge           : true      # age in days
  showIllum         : true      # percentage illumination
  showRUS           : true      # w/separator, rise/upper transit/set times for today
  showClosest       : true      # w/separator, closest phase (either ahead or behind)
  showCloseDay      : true      #  +-> closest phase date (iff showClosest is true)
  showAMPM          : false     # default is military time


refreshFrequency    : '1hr'     # 1hr is best accuracy from moon illumination data


# do the heavy lifting; escape spaces
command: "moon-phase.widget/get-phase.sh \"#{locale.city}\"  \
                                         \"#{locale.region}\""


style: """
  color             : #{option.fontColor}
  text-align        : center
  font-family       : #{option.fontName}
  left              : 85px
  top               : 15px

  background-color  : rgba(#{option.widgetBackground}, #{option.widgetOpacity})
  border-radius     : 25px
  line-height       : 1.5
  padding           : 5px
  padding-left      : 15px
  padding-right     : 15px

  icon-size = #{option.fontSize * 7}px

  @font-face
    font-family     : 'Weather'
    src url(moon-phase.widget/moon-icons.svg) format('svg')

  .moon
    display         : inline-block
    position        : relative
    text-align      : center
    white-space     : nowrap
    width           : 100%

  .current
    display         : table

  .icon
    color           : #{option.iconColor}
    display         : table-cell
    font-family     : Weather
    font-size       : icon-size
    vertical-align  : middle

  .data-elements
    display         : table-cell
    padding         : #{option.fontSize}px
    vertical-align  : middle

  .phase
    font-size       : #{option.fontSize * 1.5}px
    font-weight     : bold
  .city
    font-size       : #{option.fontSize * 1.25}px
  .coords
    font-size       : #{option.fontSize * 0.80}px
  .age
    font-size       : #{option.fontSize}px
  .illum
    font-size       : #{option.fontSize}px

  .phennames
    display         : flex
    justify-content : space-between
  .phennames div
    color           : rgba(#{option.fontColorMuted}, 0.5)
    font-size       : #{option.fontSize * 0.80}px
    width           : 30%
  .phentimes
    display         : flex
    justify-content : space-between
  .phentimes div
    font-size       : #{option.fontSize}px
    width           : 30%

  .separator
    border-top      : #{option.fontSize / 7.5}px solid rgba(#{option.fontColor}, 0.5)

  .clphase
    font-size       : #{option.fontSize * 0.85}px
  .cldate
    font-size       : #{option.fontSize * 0.85}px

  .error
    font-size       : #{option.fontSize}px
    color           : #FF0000
    background      : rgba(#000000, 0.5)

"""


option : option


render: -> """
<div class='moon'>
  <div class='current'>
    <div class='icon'></div>
    <div class='data-elements'>
      <div class='phase'></div>
      <div class='city'   #{ 'style="display:none; border-top: 0"' unless @option.showCity }></div>
      <div class='coords' #{ 'style="display:none; border-top: 0"' unless @option.showCoords }></div>
      <div class='age'    #{ 'style="display:none; border-top: 0"' unless @option.showAge }></div>
      <div class='illum'  #{ 'style="display:none; border-top: 0"' unless @option.showIllum }></div>
    </div>
  </div>

  <div class='phenomena'>
    <div class='separator' #{ 'style="display:none; border-top: 0"' unless @option.showRUS }></div>
    <div class='phennames'></div>
    <div class='phentimes'></div>
  </div>

  <div class='closest'>
    <div class='separator' #{ 'style="display:none; border-top: 0"' unless @option.showClosest }></div>
    <div class='clphase'></div>
    <div class='cldate'></div>
  </div>
</div>
"""


renderMoonData: (data) ->
  moonEl = @$domEl.find('.moon')

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

# ###FIXME
  console.error 'Moon age:', moon_age
  console.error 'Floored :', Math.floor(moon_age)
  console.error 'Rounded :', Math.round(moon_age)
  icon = @getIcon(Math.round(moon_age), @option.iconSet)
  console.error icon
  moonEl.find('.icon').html @getIcon(Math.round(moon_age), @option.iconSet)

  # if moon phase isn't modulo 25, curphase is provided
  if data.curphase?
    curphase = data.curphase
  else
    curphase = data.closestphase.phase
  moonEl.find('.phase').text "#{curphase}"

  if @option.showCity
    moonEl.find('.city').text "#{data.city}"

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

  # upcoming phennames and times; order based on current time
  if @option.showRUS
    count = Object.keys(data.moondata).length

    phen = moonEl.find('.phennames')
    phen.empty()
    if count < 3
      if data.prevmoondata?
        phenName = @returnPhennames("#{data.prevmoondata[0].phen}")
      else
        phenName = @returnPhennames("#{data.nextmoondata[0].phen}")
      phen.append "<div>#{phenName}</div>"
    for d in data.moondata
      phenName = @returnPhennames("#{d.phen}")
      phen.append "<div>#{phenName}</div>"

    time = moonEl.find('.phentimes')
    time.empty()
    if count < 3
      if data.prevmoondata?
        my_time = data.prevmoondata[0].time
      else
        my_time = data.nextmoondata[0].time
      if @option.showAMPM
        my_time = @returnAMPM(my_time)
      time.append "<div>#{my_time}</div>"
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


returnPhennames: (code) ->
  if code is "R" then return "Rises"
  if code is "U" then return "Upper Transit"
  if code is "S" then return "Sets"


getIcon: (code, iconSet) ->
  if iconSet is 'lit'
    @getLitIcon(code)
  else
    @getShadowIcon(code)

getLitIcon: (code) ->
  if code < 0  then code = 0
  if code > 28 then code = 28
  @iconLitMapping[code]

getShadowIcon: (code) ->
  if code < 0  then code = 0
  if code > 28 then code = 28
  @iconShadowMapping[code]

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

