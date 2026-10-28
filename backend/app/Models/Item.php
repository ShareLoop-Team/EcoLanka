<?php

namespace App\Models;

use App\Support\Api;
use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    public const STATUSES = ['available', 'reserved', 'donated', 'removed'];
    public const CONDITIONS = ['new', 'good', 'used'];

    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = [];

    protected function casts(): array
    {
        return ['images' => 'array', 'request_count' => 'integer'];
    }

    public function donor()
    {
        return $this->belongsTo(User::class, 'donor_id');
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'donorId' => $this->donor_id,
            'title' => $this->title,
            'description' => $this->description,
            'categoryId' => $this->category_id,
            'condition' => $this->condition,
            'images' => Api::fileUrls($this->images),
            'district' => $this->district,
            'city' => $this->city,
            'status' => $this->status,
            'requestCount' => $this->request_count,
            'createdAt' => Api::date($this->created_at),
            'updatedAt' => Api::date($this->updated_at),
        ];
    }
}
