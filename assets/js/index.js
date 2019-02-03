function filterTags(tag)
{
    var allPosts = document.querySelectorAll('[data-tag]');
    for (var post of allPosts)
    {
        var t = post.getAttribute('data-tag');
        if (tag != null && t != tag)
        {
            post.classList.add('d-none');
        }
        else
        {
            post.classList.remove('d-none');
        }
    }

    var allNavTags = document.querySelectorAll('[data-nav-tag]');
    for (var a of allNavTags)
    {
        var t = a.getAttribute('data-nav-tag');
        if ((tag != null && t == tag) || (tag == null && t == 'all'))
        {
            a.classList.add('active');
        }
        else
        {
            a.classList.remove('active');
        }
    }
}