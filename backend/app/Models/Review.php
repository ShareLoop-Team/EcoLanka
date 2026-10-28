<?php

namespace App\Models;

use App\Support\Api;
use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = [];

    protected function casts(): array
    {
        return ['rating' => 'integer'];
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'requestId' => $this->request_id,
            'reviewerId' => $this->reviewer_id,
            'revieweeId' => $this->reviewee_id,
            'rating' => $this->rating,
            'comment' => $this->comment,
            'createdAt' => Api::date($this->created_at),
        ];
    }
}
