#import "@preview/fontawesome:0.5.0": *

//------------------------------------------------------------------------------
// Style
//------------------------------------------------------------------------------

// const color
#let color-darknight = rgb("#131A28")
#let color-darkgray = rgb("#333333")
#let color-middledarkgray = rgb("#414141")
#let color-gray = rgb("#5d5d5d")
#let color-lightgray = rgb("#999999")

// Default style
#let color-accent-default = rgb("#dc3522")
#let font-header-default = ("Roboto", "Arial", "Helvetica", "Dejavu Sans")
#let font-text-default = ("Source Sans Pro", "Arial", "Helvetica", "Dejavu Sans")
#let align-header-default = center

// User defined style
$if(style.color-accent)$
#let color-accent = rgb("$style.color-accent$")
$else$
#let color-accent = color-accent-default
$endif$
$if(style.font-header)$
#let font-header = "$style.font-header$"
$else$
#let font-header = font-header-default
$endif$
$if(style.font-text)$
#let font-text = "$style.font-text$"
$else$
#let font-text = font-text-default
$endif$

//------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------

// icon string parser

#let parse_icon_string(icon_string) = {
  if icon_string.starts-with("fa ") [
    #let parts = icon_string.split(" ")
    #if parts.len() == 2 {
      fa-icon(parts.at(1), fill: color-darknight)
    } else if parts.len() == 3 and parts.at(1) == "brands" {
      fa-icon(parts.at(2), font: "Font Awesome 6 Brands", fill: color-darknight)
    } else {
      assert(false, "Invalid fontawesome icon string")
    }
  ] else if icon_string.ends-with(".svg") [
    #box(image(icon_string))
  ] else {
    assert(false, "Invalid icon string")
  }
}

// contaxt text parser
#let unescape_text(text) = {
  // This is not a perfect solution
  text.replace("\\", "").replace(".~", ". ")
}

// layout utility
#let __justify_align(left_body, right_body) = {
    box(width: 4fr)[#left_body]
    box(width: 1fr)[
      #align(right)[
        #right_body
      ]
    ]
}

#let __justify_align_3(left_body, mid_body, right_body) = {
  block[
    #box(width: 1fr)[
      #align(left)[
        #left_body
      ]
    ]
    #box(width: 1fr)[
      #align(center)[
        #mid_body
      ]
    ]
    #box(width: 1fr)[
      #align(right)[
        #right_body
      ]
    ]
  ]
}

/// Right section for the justified headers
/// - body (content): The body of the right header
#let secondary-right-header(body) = {
  set text(
    size: 10pt,
    weight: "regular",
    style: "normal",
    fill: color-gray,
  )
  body
}

/// Right section of a tertiaty headers. 
/// - body (content): The body of the right header
#let tertiary-right-header(body) = {
  set text(
    weight: "regular",
    size: 10pt,
    style: "italic",
    fill: color-lightgray,
  )
 body 
}

/// Justified header that takes a primary section and a secondary secti>on. The primary section is on the left and the secondary section is on the right.
/// - primary (content): The primary section of the header
/// - secondary (content): The secondary section of the header
#let justified-header(primary, secondary) = {
    set text(
        size: 11pt,
        weight: "bold",
        fill: color-middledarkgray)
    __justify_align(
        primary,
        secondary-right-header(secondary))
}

/// Justified header that takes a primary section and a secondary section. The primary section is on the left and the secondary section is on the right. This is a smaller header compared to the `justified-header`.
/// - primary (content): The primary section of the header
/// - secondary (content): The secondary section of the header
#let secondary-justified-header(primary, secondary) = {
  block[
     #set text(
      size: 10pt,
      weight: "regular",
      fill: color-gray,
    )
  #__justify_align[
    #primary
  ][
    #tertiary-right-header[#secondary]
  ]
 ]
}

//------------------------------------------------------------------------------
// Header
//------------------------------------------------------------------------------

#let create-header-name(
  firstname: "",
  lastname: "",
) = {
    block[
      #set text(
        size: 20pt,
        style: "normal",
        font: (font-header),
      )
      #text(fill: color-darkgray)[#firstname #lastname]
  ]
}

#let create-header-address(
  address: ""
) = {
  set text(
    color-accent,
    size: 10pt
  )

  block[#address]
}

#let create-header-contacts(
  contacts: (),
) = {
  let separator = box(width: 2pt)
  if(contacts.len() > 1) {
    block[
      #set text(
        size: 10pt,
        weight: "regular",
        style: "normal",
      )
      #align(horizon)[
        #for contact in contacts [
          #box(height: 10pt)[#parse_icon_string(contact.icon) #link(contact.url)[#contact.text]]
          #separator
        ]
      ]
    ]
  }
}

#let create-header-info(
  firstname: "",
  lastname: "",
  address: "",
  contacts: (),
  align-header: center
) = {
  set par(
   spacing: .43em 
  )
  align(align-header)[
    #create-header-name(firstname: firstname, lastname: lastname)
    #create-header-contacts(contacts: contacts)
    #create-header-address(address: address)
  ]
}

#let create-header-image(
  profile-photo: ""
) = {
  if profile-photo.len() > 0 {
    block(
      above: 15pt,
      stroke: none,
      radius: 9999pt,
      clip: true,
      image(
        fit: "contain",
        profile-photo
      )
    ) 
  }
}

#let create-header(
  firstname: "",
  lastname: "",
  address: "",
  contacts: (),
  profile-photo: "",
) = {
  if profile-photo.len() > 0 {
    block[
      #box(width: 5fr)[
        #create-header-info(
          firstname: firstname,
          lastname: lastname,
          address: address,
          contacts: contacts,
          align-header: left
        )
      ]
      #box(width: 1fr)[
        #create-header-image(profile-photo: profile-photo)
      ]
    ]
  } else {
    
    create-header-info(
      firstname: firstname,
      lastname: lastname,
      address: address,
      contacts: contacts,
      align-header: center
    )

  }
}

//------------------------------------------------------------------------------
// Resume Entries
//------------------------------------------------------------------------------

#let resume-item(details) = {
  block(below: 1em)[ 
    #set text(
      size: 10pt,
      style: "normal",
      weight: "regular",
      fill: color-darknight,
  )
    #list(indent: .60em, 
         tight: true,
         ..details)]
}

#let resume-entry(
  title: none,
  location: "",
  date: "",
  description: ""
) = {
    block[
    #set par(
      spacing: 0.43em
    )
    #justified-header(title, location)
    #secondary-justified-header(description, date)
    ]
}

//------------------------------------------------------------------------------
// Skills Entries 
//------------------------------------------------------------------------------
#let skills-entry(areas) = {
  let skills=for area in areas {
    strong[#area.at(0): ]
    area.at(1).join(", ")
    linebreak()
  }
    block[#skills]
}
//------------------------------------------------------------------------------
// Data to Resume Entries
//------------------------------------------------------------------------------

#let data-to-resume-entries(
  data: (),
) = {
  let arr = if type(data) == dictionary { data.values() } else { data }
  for item in arr [
    #resume-entry(
      title: if "title" in item { item.title } else { none },
      location: if "location" in item { item.location } else { none },
      date: if "date" in  item { item.date } else { none },
      description: if "description" in item { item.description } else { none }
    )
    #if "details" in item {
      resume-item[
        #for detail in item.details [
          - #detail
        ]
      ]
    }
  ]
}


//------------------------------------------------------------------------------
// Resume Template
//------------------------------------------------------------------------------

#let resume(
  title: "CV",
  author: (:),
  date: datetime.today().display("[month repr:long] [day], [year]"),
  profile-photo: "",
  body,
) = {
  
  set document(
    author: author.firstname + " " + author.lastname,
    title: title,
  )
  
  set text(
    font: (font-text),
    size: 11pt,
    fill: color-darkgray,
    fallback: true,
  )
  
  set page(
    paper: "a4",
    margin: (left: 15mm, right: 12mm, top: 12.50mm, bottom: 0mm),
    footer:  [
      #set text(
        fill: gray,
        size: 8pt,
      )
      #__justify_align_3[
        #smallcaps[#date]
      ][
        #smallcaps[
          #author.firstname
          #author.lastname
          #sym.dot.c
        ]
      ][
        #context(counter(page).display())
      ]
    ],
  )
  
  // set paragraph spacing
  set par(
    spacing: 0.65em,
    justify: true,
  )

  set heading(
    numbering: none,
    outlined: false,
  )
  
  show heading.where(level: 1): it => [
    #set text(
      size: 14pt,
      weight: "regular",
    )
    
    #align(left)[
      #text[#strong[#text(color-accent)[#it.body]]]
      #box(width: 1fr, line(length: 100%))
    ]
  ]
  
  show heading.where(level: 2): it => {
    set text(
      color-middledarkgray,
      size: 12pt,
      weight: "regular"
    )
    it.body
  }
  
  show heading.where(level: 3): it => {
    set text(
      size: 10pt,
      weight: "regular",
      fill: color-gray,
    )
    smallcaps[#it.body]
  }
  
  // Contents
  create-header(firstname: author.firstname,
                lastname: author.lastname,
                address: author.address,
                contacts: author.contacts,
                profile-photo: profile-photo,)
  body
}