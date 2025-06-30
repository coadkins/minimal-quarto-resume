// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

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
#let color-accent = rgb("dc3522")
#let color-accent = rgb("DC143C")
#let font-header = "Roboto"
#let font-text = "Source Sans Pro"

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
    size: 10pt,
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

// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: resume.with(
  author: (
    firstname: unescape_text("Cory"),
    lastname: unescape_text("Adkins"),
    address: unescape_text("Boston, MA"),
    position: unescape_text(""),
    contacts: ((
      text: unescape_text("adkins.cory\@gmail.com"),
      url: unescape_text("mailto:adkins.cory\@gmail.com"),
      icon: unescape_text("fa envelope"),
    ), (
      text: unescape_text("GitHub"),
      url: unescape_text("https:\/\/github.com/coadkins"),
      icon: unescape_text("fa brands github"),
    ), (
      text: unescape_text("LinkedIn"),
      url: unescape_text("https:\/\/linkedin.com/in/corykadkins"),
      icon: unescape_text("fa brands linkedin"),
    )),
  ),
)

= Education
<education>
#resume-entry(title: "Master of Science (MS), Political Science",location: "Cambridge, MA",date: "2025-09-01",description: "Massachusetts Institute of Technology",)
#resume-item(([Passed doctoral exams in models and methods],))
#resume-entry(title: "Juris Doctor (JD)",location: "New Haven, CT",date: "2016-09-01",description: "Yale University",)
#resume-item(([Passed NY Bar Exam],))
#resume-entry(title: "Bachelor of Arts (BA), Philosophy",location: "Durham, NC",date: "2013-05-21",description: "Duke University",)
#resume-item(([Benjamin N. Duke Scholarship],
[High Distinction],))
= Experience
<experience>
#resume-entry(title: "PhD Candidate Researcher",location: "Cambridge",date: "2025-05-31",description: "MIT",)
#resume-item(([Item1],
[Item2],))
= Skills
<skills>
#skills-entry((
("Machine Learning & Modeling", (
[Python(Scikit-learn)],
[R (Tidymodels)],
[Stan],
)),
("Databases", (
[Duckdb],
[PostgresSQL],
)),
("Programming Languages", (
[Python],
[R],
[SQL],
)),
))




