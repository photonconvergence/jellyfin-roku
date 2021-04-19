sub setFields()
    json = m.top.json

    m.top.id = json.id
    m.top.Title = json.name
    m.top.Type = "Folder"

    m.top.iconUrl = "pkg:/images/media_type_icons/folder_white.png"
    setPoster()
end sub

sub setPoster()
  if m.top.image <> invalid
    m.top.posterURL = m.top.image.url
  else if m.top.json.ImageTags.Primary <> invalid then
    imgParams = { "maxHeight": 440, "maxWidth": 295, "Tag": m.top.json.ImageTags.Primary }
    m.top.posterURL = ImageURL(m.top.json.id, "Primary", imgParams)
  end if
end sub
