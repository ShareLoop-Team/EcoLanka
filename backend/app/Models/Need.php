<?php

namespace App\Models;

use App\Support\Api;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

class Need extends Model
{
    use HasUlids;

    public const STATUSES = ['open', 'fulfilled', 'closed'];

    protected $guarded = [];

    protected function casts(): array
    {
        return ['anti_resell_agreed' => 'boolean'];
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'requesterId' => $this->requester_id,
            'title' => $this->title,
            'description' => $this->description,
            'reason' => $this->reason,
            'categoryId' => $this->category_id,
            'district' => $this->district,
            'city' => $this->city,
            'status' => $this->status,
            'antiResellAgreed' => $this->anti_resell_agreed,
            'createdAt' => Api::date($this->created_at),
            'updatedAt' => Api::date($this->updated_at),
        ];
    }
}
