<?php

namespace App\Models;

use App\Support\Api;
use Illuminate\Database\Eloquent\Model;

/** requests/{itemId}_{requesterId} — one request per item per user. */
class ShareRequest extends Model
{
    public const HANDOVER_METHODS = ['direct', 'courier', 'on_demand'];

    public $incrementing = false;

    protected $keyType = 'string';

    protected $table = 'share_requests';

    protected $guarded = [];

    protected function casts(): array
    {
        return ['anti_resell_agreed' => 'boolean'];
    }

    public static function idFor(string $itemId, string $requesterId): string
    {
        return $itemId.'_'.$requesterId;
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    public function involves(User $user): bool
    {
        return $user->id === $this->donor_id || $user->id === $this->requester_id;
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'itemId' => $this->item_id,
            'itemTitle' => $this->item_title,
            'donorId' => $this->donor_id,
            'requesterId' => $this->requester_id,
            'message' => $this->message,
            'antiResellAgreed' => $this->anti_resell_agreed,
            'handoverMethod' => $this->handover_method,
            'status' => $this->status,
            'createdAt' => Api::date($this->created_at),
            'updatedAt' => Api::date($this->updated_at),
        ];
    }
}
