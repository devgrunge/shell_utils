const allContent = []

function createCSV(data, fileName) {
  const headers = [
    'id',
    'email',
    'firstName',
    'lastName',
    'postId',
    'postText',
    'postAuthor',
    'postAuthorId',
    'postAuthorUrl',
    'commentId',
    'commentText',
    'commentAuthorName',
    'commentAuthorId',
    'commentAuthorUrl',
    'timestamp',
    'commentUrl',
  ]

  const csvContent = [
    headers.join(','),
    ...data.map((row) =>
      headers
        .map((header) => {
          const value = row[header]
          if (value === null) return 'null'
          if (typeof value === 'string') {
            // Wrap all fields, including those without commas, in double quotes
            return `"${value.replace(/"/g, '""')}"`
          }
          return value
        })
        .join(','),
    ),
  ].join('\n')

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')

  if (navigator.msSaveBlob) {
    // IE 10+
    navigator.msSaveBlob(blob, fileName)
  } else {
    const url = URL.createObjectURL(blob)

    link.setAttribute('href', url)
    link.setAttribute('download', fileName || 'data.csv')
    document.body.appendChild(link)

    link.click()

    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  }
}

async function scrollDown() {
  // const wrapper = document.querySelector("#search-page-list-container");
  const wrapper = window
  await new Promise((resolve, reject) => {
    var totalHeight = 0
    var distance = 800

    var timer = setInterval(async () => {
      var scrollHeightBefore = wrapper.scrollHeight
      wrapper.scrollBy(0, distance)
      totalHeight += distance

      clearInterval(timer)
      resolve()
    }, 400)
  })
  await new Promise((resolve) => setTimeout(resolve, 1000))
}

function getEmailFromText(text) {
  const emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g
  const email = text?.match(emailRegex)?.[0]
  return email || ''
}

function clickOnComments(post) {
  // Get all divs on the page
  var allDivs = post.getElementsByTagName('div')

  // Create an array to store matching divs
  var matchingDivs = []

  // Loop through each div
  for (var i = 0; i < allDivs.length; i++) {
    // Check if the div has the attribute data-visualcompletion set to "ignore-dynamic"
    if (allDivs[i].getAttribute('data-visualcompletion') === 'ignore-dynamic') {
      // Add the matching div to the array
      matchingDivs.push(allDivs[i])
      const thingToClickToOpenComments =
        allDivs?.[i]?.children?.[0]?.children?.[0]?.children?.[0]?.children?.[0]
          ?.children?.[0]?.children?.[1]?.children?.[1]?.children?.[0]
          ?.children?.[0]
      if (thingToClickToOpenComments) {
        thingToClickToOpenComments.click()
      }
    }
  }
}

// Function to recursively traverse HTML elements and return text in an array
function traverseElementsToGetText(element) {
  var textArray = []

  // Check if the element has child nodes
  if (element.childNodes.length > 0) {
    // Loop through each child node
    for (var i = 0; i < element.childNodes.length; i++) {
      // Recursively call the function for each child node
      textArray = textArray.concat(
        traverseElementsToGetText(element.childNodes[i]),
      )
    }
  } else {
    // If the element is a text node and contains non-whitespace text
    if (
      element.nodeType === Node.TEXT_NODE &&
      element.nodeValue.trim() !== ''
    ) {
      // Push the text into the text array
      textArray.push(element.nodeValue.trim())
    }
  }

  return textArray
}

function getAllPosts() {
  const posts = document.querySelectorAll('div[data-pagelet^="GroupFeed"] > div')
  return [...posts].filter((post) => {
    const posterName = post?.querySelector('h2')?.textContent
    if (posterName) {
      return true
    }
    return false
  })
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function closeDialog() {
  const closeButton = document?.querySelector('div[aria-label="Close"]')
  if (!closeButton) {
    return
  }
  closeButton.click()
}

function formatTopLevelComments(postId, topLevelComments = []) {
  return topLevelComments.map((c) => {
    const text = c?.comment.body.text
    const commentId = c?.comment.id
    const authorName = c?.comment.author.name
    const authorId = c?.comment.author.id
    return {
      id: commentId,
      commentId,
      postId,
      commentText: text || '',
      commentAuthorName: authorName,
      commentAuthorId: authorId,
      email: getEmailFromText(text),
      firstName: authorName?.split(' ')?.[0],
      lastName: authorName?.split(' ')?.[1],
    }
  })
}

function parseFirstLevelJson(json) {
  const actor =
    json?.data?.node?.group_feed?.edges?.[0]?.node?.comet_sections?.content
      ?.story?.comet_sections?.context_layout?.story?.comet_sections
      ?.actor_photo?.story?.actors?.[0]

  const postText =
    json?.data?.node?.group_feed?.edges?.[0]?.node?.comet_sections?.content
      ?.story?.comet_sections?.message_container?.story?.message?.text
  const postId =
    json?.data?.node?.group_feed?.edges?.[0]?.node?.comet_sections?.feedback
      ?.story?.post_id

  const post = {
    id: postId,
    postId,
    postText: postText || '',
    postAuthor: actor?.name,
    postAuthorId: actor?.id,
    postAuthorUrl: actor?.url,
    email: getEmailFromText(postText),
    firstName: actor?.name?.split(' ')?.[0],
    lastName: actor?.name?.split(' ')?.[1],
  }

  const topLevelComments = formatTopLevelComments(
    postId,
    json?.data?.node?.group_feed?.edges?.[0]?.node?.comet_sections?.feedback
      ?.story?.feedback_context?.interesting_top_level_comments,
  )
  return {
    post,
    topLevelComments,
  }
}

function parseSecondLevelJson(json) {
  const data2 = json
  const actor =
    data2?.data?.node?.comet_sections?.content?.story?.comet_sections
      ?.context_layout?.story?.comet_sections?.actor_photo?.story?.actors?.[0]

  const posterName = actor?.name
  const postText =
    data2?.data?.node?.comet_sections?.content?.story?.comet_sections
      ?.message_container?.story?.message?.text
  const id = actor?.id
  const postId = data2?.data?.node?.comet_sections?.feedback?.story?.post_id
  const url = actor?.url

  const post = {
    id: postId,
    postId,
    postText: postText || '',
    postAuthor: posterName,
    postAuthorId: id,
    postAuthorUrl: url,
    email: getEmailFromText(postText),
    firstName: posterName?.split(' ')?.[0],
    lastName: posterName?.split(' ')?.[1],
  }

  const topLevelComments = formatTopLevelComments(
    postId,
    data2?.data?.node?.comet_sections?.feedback?.story?.feedback_context
      ?.interesting_top_level_comments,
  )

  return {
    post,
    topLevelComments,
  }
}

function parseThirdLevelJson(json) {
  const data3 = json
  const actor3 =
    data3?.data?.node?.comet_sections?.content?.story?.comet_sections
      ?.context_layout?.story?.comet_sections?.actor_photo?.story?.actors?.[0]
  const posterName = actor3?.name
  const postText =
    data3?.data?.node?.comet_sections?.content?.story?.comet_sections
      ?.message_container?.story?.message?.text
  const posterId = actor3?.id
  const postId = data3?.data?.node?.comet_sections?.feedback?.story?.post_id
  const url = actor3?.url
  const post = {
    id: postId,
    postId,
    postText: postText || '',
    postAuthor: posterName,
    postAuthorId: posterId,
    postAuthorUrl: url,
    email: getEmailFromText(postText),
    firstName: posterName?.split(' ')?.[0],
    lastName: posterName?.split(' ')?.[1],
  }

  const topLevelComments = formatTopLevelComments(
    postId,
    data3?.data?.node?.comet_sections?.feedback?.story?.feedback_context
      ?.interesting_top_level_comments,
  )

  return {
    post,
    topLevelComments,
  }
}

function addCommentsToAllContent(comments = []) {
  comments.forEach((c) => {
    if (allContent?.find((f) => f.commentId === c.commentId)) {
    } else {
      allContent.push(c)
    }
  })
}

function interceptRequests() {
  let oldXHROpen = window.XMLHttpRequest.prototype.open
  window.XMLHttpRequest.prototype.open = function (method, url, async) {
    if (!url.includes('graphql')) {
      return oldXHROpen.apply(this, arguments)
    }
    // Capture the request body
    let requestBody = null

    // Override the send method to capture the request body
    let oldXHRSend = this.send
    this.send = function (data) {
      requestBody = data
      oldXHRSend.apply(this, arguments)
    }

    // Listen for the 'load' event to capture the response
    this.addEventListener('load', function () {
      if (
        requestBody?.includes('GroupsCometFeedRegularStoriesPaginationQuery')
      ) {
        console.log('getting posts')
        // we're getting posts....
        const payload = this.responseText
        const lines = payload.split('\n')

        const data1 = JSON.parse(lines[0])
        const firstPost = parseFirstLevelJson(data1)
        console.log('firstPost', firstPost)

        const data2 = JSON.parse(lines[1])
        const secondPost = parseSecondLevelJson(data2)
        console.log('secondPost', secondPost)

        const data3 = JSON.parse(lines[2])
        const thirdPost = parseThirdLevelJson(data3)
        console.log('thirdPost', thirdPost)

        allContent.push(firstPost.post)
        addCommentsToAllContent(firstPost.topLevelComments)
        allContent.push(secondPost.post)
        addCommentsToAllContent(secondPost.topLevelComments)
        allContent.push(thirdPost.post)
        addCommentsToAllContent(thirdPost.topLevelComments)
        //
      } else if (requestBody?.includes('CometFocusedStoryViewUFIQuery')) {
        console.log('getting comments')
        // we're getting comments
        let data = null
        try {
          data = JSON.parse(this.responseText)
        } catch (e) {}
        const postId = data?.data?.story_card?.post_id
        const comments =
          data?.data?.feedback?.ufi_renderer?.feedback?.comment_list_renderer?.feedback?.comment_rendering_instance_for_feed_location?.comments?.edges?.map(
            (blah) => {
              const comment = blah?.node
              const commentId = comment?.id
              const commentText = comment?.body?.text
              const authorName = comment?.author?.name
              const authorId = comment?.author?.id
              const authorUrl = comment?.author?.url
              const timeStuff = comment?.comment_action_links?.find(
                (f) => f?.__typename === 'XFBCommentTimeStampActionLink',
              )?.comment
              const timestamp = timeStuff?.created_time
              const commentUrl = timeStuff?.url
              const email = getEmailFromText(commentText)

              return {
                id: commentId,
                commentId,
                postId,
                commentText,
                commentAuthorName: authorName,
                commentAuthorId: authorId,
                commentAuthorUrl: authorUrl,
                timestamp,
                commentUrl,
                email,
                firstName: authorName?.split(' ')?.[0],
                lastName: authorName?.split(' ')?.[1],
              }
            },
          )
        addCommentsToAllContent(comments)
        console.log('comments', comments)
      } else {
        return
      }
    })

    // Call the original open method
    return oldXHROpen.apply(this, arguments)
  }
}

async function run() {
  interceptRequests()
  console.log('starting...')
  let posts = getAllPosts()
  console.log('posts.length', posts.length)
  let i = 0

  while (i < posts.length) {
    const post = posts[i]
    console.log(
      `while you're waiting, why not check out https://thewebscrapingguy.com/? 😅`,
    )
    clickOnComments(post)
    await sleep(1000)
    closeDialog()

    i++
    if (scrolls > 0) {
      await scrollDown()
      scrolls--
      console.log('scrolls left', scrolls)
      console.log('old posts', posts.length)
      const currentPosts = getAllPosts()
      console.log('currentPosts', currentPosts.length)
      posts = currentPosts
    }
  }

  createCSV(allContent, 'facebookGroupPostsAndComments.csv')
  console.log('allContent', allContent)
  console.log('done!')
  console.log(
    `Congrats! 🎉 You scraped a sh*t ton of posts! If you need any custom scrapers built, email me: adrian@thewebscrapingguy.com`,
  )
}

let scrolls = 50
// NOTE: Only gets the first level comments
await run()