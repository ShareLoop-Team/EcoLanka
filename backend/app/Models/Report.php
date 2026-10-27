<?php

namespace App\Models;

use App\Support\Api;
use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    public const TARGET_TYPES = ['user', 'item'];
    public const REASONS = ['spam', 'resell', 'fraud', 'inappropriate', 'other'];
    public const STATUSES = ['open', 'reviewing', 'resolved', 'dismissed'];

    public $incrementing = false;

    protected $keyType = 'string';

    protected $guarded = [];

    protected function casts(): array
    {
        return ['evidence' => 'array'];
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'reporterId' => $this->reporter_id,
            'targetType' => $this->target_type,
            'targetId' => $this->target_id,
            'reason' => $this->reason,
            'details' => $this->details,
            'evidence' => Api::fileUrls($this->evidence),
            'status' => $this->status,
            'createdAt' => Api::date($this->created_at),
        ];
    }
}
