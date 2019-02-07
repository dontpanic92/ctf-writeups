function filterTags(tag)
{
    var allPosts = document.querySelectorAll('[data-tag]');
    console.log(allPosts);
    console.log(tag);
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

function initFlags()
{
    var elems = document.body.getElementsByTagName("flag");
    console.log(elems);
    for (var e of elems)
    {
        e.style.backgroundColor = "#000";
        e.onmouseover = function() { e.style.color = "#FFF"; };
        e.onmouseleave = function() { e.style.color = "#000"; };
        e.onmouseleave();
    }
}

window.onload=initFlags;
