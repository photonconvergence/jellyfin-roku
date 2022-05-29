sub init()
    m.top.optionsAvailable = false

    setupAudioNode()
    setupButtons()
    setupInfoNodes()

    m.LoadMetaDataTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadMetaDataTask.itemsToLoad = "metaData"

    m.LoadBackdropImageTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadBackdropImageTask.itemsToLoad = "backdropImage"

    m.LoadAudioStreamTask = CreateObject("roSGNode", "LoadItemsTask")
    m.LoadAudioStreamTask.itemsToLoad = "audioStream"

    m.currentSongIndex = 0
    m.buttonsNeedToBeLoaded = true
end sub

sub setupAudioNode()
    m.top.audio = createObject("RoSGNode", "Audio")
    m.top.audio.observeField("state", "audioStateChanged")
end sub

sub setupButtons()
    m.buttons = m.top.findNode("buttons")
    m.top.observeField("selectedButtonIndex", "selectedButtonChanged")
    m.previouslySelectedButtonIndex = 1
    m.top.selectedButtonIndex = 1
end sub

sub selectedButtonChanged()
    selectedButton = m.buttons.getChild(m.previouslySelectedButtonIndex)
    selectedButton.uri = selectedButton.uri.Replace("-selected", "-default")

    selectedButton = m.buttons.getChild(m.top.selectedButtonIndex)
    selectedButton.uri = selectedButton.uri.Replace("-default", "-selected")
end sub

sub setupInfoNodes()
    m.albumCover = m.top.findNode("albumCover")
    m.backDrop = m.top.findNode("backdrop")
end sub

sub audioStateChanged()
    ' Song Finished, attempt to move to next song
    if m.top.audio.state = "finished"
        if m.currentSongIndex < m.top.pageContent.count() - 1
            LoadNextSong()
        else
            ' Return to previous screen
            m.top.state = "finished"
        end if
    end if
end sub

function playAction() as boolean
    if m.top.audio.state = "playing"
        m.top.audio.control = "pause"
    else if m.top.audio.state = "paused"
        m.top.audio.control = "resume"
    end if

    return true
end function

function previousClicked() as boolean
    if m.currentSongIndex > 0
        m.currentSongIndex--
        pageContentChanged()
    end if

    return true
end function

function nextClicked() as boolean
    if m.currentSongIndex < m.top.pageContent.count() - 1
        LoadNextSong()
    end if

    return true
end function

sub LoadNextSong()
    m.currentSongIndex++
    pageContentChanged()
end sub

' Update values on screen when page content changes
sub pageContentChanged()
    m.LoadMetaDataTask.itemId = m.top.pageContent[m.currentSongIndex]
    m.LoadMetaDataTask.observeField("content", "onMetaDataLoaded")
    m.LoadMetaDataTask.control = "RUN"

    m.LoadAudioStreamTask.itemId = m.top.pageContent[m.currentSongIndex]
    m.LoadAudioStreamTask.observeField("content", "onAudioStreamLoaded")
    m.LoadAudioStreamTask.control = "RUN"
end sub

sub onAudioStreamLoaded()
    data = m.LoadAudioStreamTask.content[0]
    m.LoadAudioStreamTask.unobserveField("content")
    if data <> invalid and data.count() > 0
        m.top.audio.content = data
        m.top.audio.control = "stop"
        m.top.audio.control = "none"
        m.top.audio.control = "play"
    end if
end sub

sub onBackdropImageLoaded()
    data = m.LoadBackdropImageTask.content[0]
    m.LoadBackdropImageTask.unobserveField("content")
    if isValid(data) and data <> ""
        setBackdropImage(data)
    end if
end sub

sub onMetaDataLoaded()
    data = m.LoadMetaDataTask.content[0]
    m.LoadMetaDataTask.unobserveField("content")
    if data <> invalid and data.count() > 0

        ' Use metadata to load backdrop image
        m.LoadBackdropImageTask.itemId = data.json.ArtistItems[0].id
        m.LoadBackdropImageTask.observeField("content", "onBackdropImageLoaded")
        m.LoadBackdropImageTask.control = "RUN"

        setPosterImage(data.posterURL)
        setScreenTitle(data.json)
        setOnScreenTextValues(data.json)

        ' If we have more and 1 song to play, fade in the next and previous controls
        if m.buttonsNeedToBeLoaded
            if m.top.pageContent.count() > 1
                m.floatanimation = m.top.FindNode("displayButtonsAnimation")
                m.floatanimation.control = "start"
            end if
            m.buttonsNeedToBeLoaded = false
        end if
    end if
end sub

' Set poster image on screen
sub setPosterImage(posterURL)
    if isValid(posterURL)
        if m.albumCover.uri <> posterURL
            m.albumCover.uri = posterURL
        end if
    end if
end sub

' Set screen's title text
sub setScreenTitle(json)
    newTitle = ""
    if isValid(json)
        if isValid(json.AlbumArtist)
            newTitle = json.AlbumArtist
        end if
        if isValid(json.AlbumArtist) and isValid(json.name)
            newTitle = newTitle + " / "
        end if
        if isValid(json.name)
            newTitle = newTitle + json.name
        end if
    end if

    if m.top.overhangTitle <> newTitle
        m.top.overhangTitle = newTitle
    end if
end sub

' Populate on screen text variables
sub setOnScreenTextValues(json)
    if isValid(json)
        setFieldTextValue("numberofsongs", "Track " + stri(m.currentSongIndex + 1) + "/" + stri(m.top.pageContent.count()))
        setFieldTextValue("artist", json.Artists[0])
        setFieldTextValue("song", json.name)
    end if
end sub

' Add backdrop image to screen
sub setBackdropImage(data)
    if isValid(data)
        if m.backDrop.uri <> data
            m.backDrop.uri = data
        end if
    end if
end sub

' Process key press events
function onKeyEvent(key as string, press as boolean) as boolean

    ' Key bindings for remote control buttons
    if press
        if key = "play"
            return playAction()
        else if key = "back"
            m.top.audio.control = "stop"
        else if key = "rewind"
            return previousClicked()
        else if key = "fastforward"
            return nextClicked()
        else if key = "left"
            if m.top.pageContent.count() = 1 then return false
            
            if m.top.selectedButtonIndex > 0 
                m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
                m.top.selectedButtonIndex = m.top.selectedButtonIndex - 1
            end if
            return true
        else if key = "right"
            if m.top.pageContent.count() = 1 then return false

            m.previouslySelectedButtonIndex = m.top.selectedButtonIndex
            if m.top.selectedButtonIndex < 2 then m.top.selectedButtonIndex = m.top.selectedButtonIndex + 1
            return true
        else if key = "OK"
            if m.buttons.getChild(m.top.selectedButtonIndex).id = "play"
                return playAction()
            else if m.buttons.getChild(m.top.selectedButtonIndex).id = "previous"
                return previousClicked()
            else if m.buttons.getChild(m.top.selectedButtonIndex).id = "next"
                return nextClicked()
            end if
        end if
    end if

    return false
end function
