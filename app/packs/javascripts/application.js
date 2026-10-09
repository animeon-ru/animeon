import Turbolinks from 'turbolinks';
Turbolinks.start();

$(document).on('turbolinks:load', () => {
  function Data() {
    const formData = new FormData();
    //const file = $('#video_video_file')[0].files[0];
    //formData.append('video[video_file]', file);
    formData.append('video[episode_id]', $('#ep-id').text());
    formData.append('video[fandub]', $('#video_fandub').val())
    formData.append('video[quality][]', $('#video_quality').val())
    return formData
  }

  $('.video_choose_button').on('click', function (e) {
    let id = $(e.currentTarget).attr('video_id')
    $('.video_choose_button').removeClass('is-active').attr('aria-pressed', 'false')
    $(e.currentTarget).addClass('is-active').attr('aria-pressed', 'true')
    $.ajax({
      url: '/api/videos/' + id + '',
      type: 'GET',
      data: null,
      processData: false,
      contentType: false,
      headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
      success: function (response) {
        $('.anime-video-player').remove()
        $('.video_block').append('<div id="' + id + '" class="anime-video-player"></div>')
        let player = new window.Playerjs({id: id, file: "[480]" + response[0].url + ',[720]' + response[1].url + ',[1080]' + response[2].url});
      },
      error: function (error) {
        console.log(error)
      }
    })
  })

  $('.approve_changes').on('click', function (e) {
    $.ajax({
      url: '/api/db_modifications/' + e.currentTarget.id + '/approve',
      type: 'POST',
      data: null,
      processData: false,
      contentType: false,
      headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
      success: function (response) {
        $('#status-'+e.currentTarget.id).html(response.status)
      },
      error: function (error) {
        console.log(error)
      }
    })
  })
  $('.rollback_changes').on('click', function (e) {
    $.ajax({
      url: '/api/db_modifications/' + e.currentTarget.id + '/rollback',
      type: 'POST',
      data: null,
      processData: false,
      contentType: false,
      headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
      success: function (response) {
        $('#status-'+e.currentTarget.id).html(response.status)
      },
      error: function (error) {
        console.log(error)
      }
    })
  })
  $('.destroy_modification').on('click', function (e) {
    $.ajax({
      url: '/api/db_modifications/' + e.currentTarget.id,
      type: 'DELETE',
      data: null,
      processData: false,
      contentType: false,
      headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
      success: function (response) {
        $('tr#'+e.currentTarget.id).remove()
      },
      error: function (error) {
        console.log(error)
      }
    })
  })

  $('#btn-submit').on('click', function (e) {
    e.preventDefault();
    $('#btn-submit').prop({disabled: true})
    const formData = Data()
    const file = $('#video_video_file')[0].files[0]
    if ($('#ep-id').attr('uploaded') == null) {
      $.ajax({
        url: '/api/videos',
        type: 'POST',
        data: formData,
        processData: false,
        contentType: false,
        headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
        success: async function (response) {
          $('#ep-id').attr({uploaded: response.video.id})
          const presign = await fetch("/api/videos/" + response.video.id + "/presign", {
            method: "POST",
            headers: {"Content-Type": "application/json", 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
            body: JSON.stringify({filename: file.name})
          }).then(r => r.json());
          $(".btns").append("<div class='loading-container' style=\"width: 30px; height: 30px;\">\n" +
            "    <div class=\"loading loading--full-height\"></div>\n" +
            "</div>")
          await putWithProgress(presign.url, file, ({ pct }) => {
            $('.loading-percentage').html("Загрузка:" + pct + " %")
          }).then(async function () {
            await fetch("/api/videos/" + response.video.id, {
              method: "PATCH",
              headers: {
                "Content-Type": "application/json",
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
              },
              body: JSON.stringify({
                video_file_file_name: file.name,
                video_file_content_type: file.type,
                video_file_file_size: file.size
              })
            });
            $('.btns')
              .prepend('<div class="btn" id="btn-next">Следующий эпизод</div>')
              .prepend('<div class="btn" id="btn-save">Сохранить</div>')
            $('.loading-container').html('<div class="ok" role="img" aria-label="Success"></div>')
            $('#btn-submit').remove()
          });
        },
        error: function (e) {
          console.log(e)
        }
      });
    }
  });
  function putWithProgress(url, file, onProgress) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open("PUT", url, true);

      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          const pct = Math.round((e.loaded / e.total) * 100);
          onProgress?.({ loaded: e.loaded, total: e.total, pct });
        }
      };

      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          resolve();
          $('.loading-percentage').html("Успешно загружено")
        }
        else reject(new Error(`S3 upload failed: ${xhr.status} ${xhr.responseText}`));
      };

      xhr.onerror = () => reject(new Error("Network error during upload"));
      xhr.send(file);
    });
  }
  $(document).on('click', '#btn-save', function (e) {
    e.preventDefault();
    const formData = new FormData()
    formData.append('video[status]', 0)
    if ($('#ep-id').attr('uploaded') != null) {
      $.ajax({
        url: '/api/videos/' + $('#ep-id').attr('uploaded') + '/update_status',
        type: 'PATCH',
        data: formData,
        processData: false,
        contentType: false,
        headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
        success: function (response) {
          Turbolinks.visit('/animes/' + response.anime.id + '/episodes/' + response.episode.id)
        },
        error: function () {
          $('#progress-bar').css('background-color', 'red');
          $('#btn-submit').prop({disabled: false})
        }
      })
    }
  })
  $(document).on('click', '#btn-next', function (e) {
    e.preventDefault();
    const formData = new FormData()
    formData.append('video[status]', 0)
    if ($('#ep-id').attr('uploaded') != null) {
      $.ajax({
        url: '/api/videos/' + $('#ep-id').attr('uploaded') + '/update_status',
        type: 'PATCH',
        data: formData,
        processData: false,
        contentType: false,
        headers: {'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')},
        success: function (response) {
          if (response.next_episode == null) {
            Turbolinks.visit('/animes/' + response.anime.id)
          } else {
            Turbolinks.visit('/animes/' + response.anime.id + '/episodes/' + response.next_episode.id + '/videos/new?fandub=' + response.video.fandub_id)
          }
        },
        error: function () {
          $('#progress-bar').css('background-color', 'red');
          $('#btn-submit').prop({disabled: false})
        }
      })
    }
  })

  $('.anime-form input[type="file"]').on('change', function (e) {
    const file = e.currentTarget.files[0]
    if (!file) return
    const url = URL.createObjectURL(file)
    $('#poster-preview-empty').remove()
    let img = $('#poster-preview-img')
    if (img.length === 0) {
      img = $('<img id="poster-preview-img" alt="">').appendTo('.poster-preview')
    }
    img.attr('src', url)
  })

  let input = $('.search-field');
  input.on('keyup', function (e){
    if (e.keyCode === 13) {
      Turbolinks.visit('/animes?name='+input.val())
      console.log('enter')
    }
    if (e.keyCode === 27) {
      input.val('')
      $('.search-results').html('')
    }
    search(input.val())
  })

  input.focusin(function () {
    search(input.val())
  })

  function search(value){
    if (value !== "") {
      $.ajax({
        url: '/api/animes/search?name='+value,
        method: 'get',
        dataType: 'json',
        success: function (data) {

          const res = data.map(anime => "" +
            "<a href='/animes/"+anime.id+"'>" +
            "<div class='search-result'>" +
            "<div class='search-result-img'>" +
            "<img width='50px' src='https://proxy.animeon.ru/anime-posters/mini/"+anime.id+".webp'>" +
            "</div>" +
            "<div class='search-result-name'>" +
            "<span>"+anime.russian+" / "+anime.name+"</span>" +
            "</div>" +
            "</div>" +
            "</a>").join('')
          $('.search-results').html(res)
        }
      })
    }
  }
})
