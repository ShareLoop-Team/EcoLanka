<?php

namespace App\Models;

use App\Support\Api;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

/** In-app notifications (written by the server alongside each change). */
class AppNotification extends Model
{
    use HasUlids;

    protected $table = 'notifications';

    protected $guarded = [];

    protected function casts(): array
    {
        return ['read' => 'boolean'];
    }

    /** Notification for the other side of a share request. */
    public static function forRequest(ShareRequest $r, string $to, string $from, string $type, string $title, string $body): self
    {
        return self::create([
            'user_id' => $to,
            'sender_id' => $from,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'request_id' => $r->id,
            'item_id' => $r->item_id,
            'read' => false,
        ]);
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'userId' => $this->user_id,
            'senderId' => $this->sender_id,
            'type' => $this->type,
            'title' => $this->title,
            'body' => $this->body,
            'requestId' => $this->request_id,
            'itemId' => $this->item_id,
            'needId' => $this->need_id,
            'read' => $this->read,
            'createdAt' => Api::date($this->created_at),
        ];
    }
}
