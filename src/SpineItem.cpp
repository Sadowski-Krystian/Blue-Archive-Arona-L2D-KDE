#include "SpineItem.h"
#include <QSGGeometryNode>
#include <QSGTextureMaterial>
#include <QSGTransformNode>
#include <QQuickWindow>
#include <QFileInfo>
#include <QDir>
#include <QDebug>

// 1. Texture Loader Bridge (Fixed string concatenation)
class QtTextureLoader : public spine::TextureLoader {
public:
    void load(spine::AtlasPage& page, const spine::String& path) override {
        QFileInfo info(QString::fromUtf8(path.buffer()));
        QString fullPath = QString::fromUtf8("package/contents/assets/") + info.fileName();
        
        QImage* image = new QImage(fullPath);
        
        if (image->isNull()) {
            qWarning() << "CRITICAL: Image not found at" << fullPath;
        }

        page.setRendererObject(image); // 3.8 API
        page.width = image->width();
        page.height = image->height();
    }

    void unload(void* texture) override {
        delete static_cast<QImage*>(texture);
    }
};

SpineItem::SpineItem(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
    m_textureLoader = new QtTextureLoader();
    m_timer.start();

    connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow* window) {
        if (window) {
            connect(window, &QQuickWindow::beforeSynchronizing, this, &SpineItem::updateAnimation);
        }
    });
}

SpineItem::~SpineItem() {
    delete m_animationState;
    delete m_animationStateData;
    delete m_skeleton;
    delete m_skeletonData;
    delete m_atlas;
    delete m_textureLoader;
    
    for (QSGTexture* tex : std::as_const(m_textures)) {
        delete tex;
    }
    m_textures.clear();
}

void SpineItem::setSkelSource(const QString &source) {
    if (m_skelSource != source) {
        m_skelSource = source;
        loadSkeleton();
        Q_EMIT sourceChanged();
    }
}

void SpineItem::setAtlasSource(const QString &source) {
    if (m_atlasSource != source) {
        m_atlasSource = source;
        loadSkeleton();
        Q_EMIT sourceChanged();
    }
}

void SpineItem::setAnimation(const QString &animationName) {
    m_animation = animationName;
    if (m_animationState && !m_animation.isEmpty()) {
        m_animationState->setAnimation(0, spine::String(m_animation.toUtf8().constData()), true);
    }
    Q_EMIT animationChanged();
}

void SpineItem::loadSkeleton() {
    if (m_skelSource.isEmpty() || m_atlasSource.isEmpty()) return;

    delete m_animationState; m_animationState = nullptr;
    delete m_skeleton; m_skeleton = nullptr;
    delete m_skeletonData; m_skeletonData = nullptr;
    delete m_atlas; m_atlas = nullptr;

    spine::String atlasPath(m_atlasSource.toUtf8().constData());
    m_atlas = new spine::Atlas(atlasPath, m_textureLoader);

    spine::SkeletonBinary binary(m_atlas);
    binary.setScale(1.0f);

    spine::String skelPath(m_skelSource.toUtf8().constData());
    m_skeletonData = binary.readSkeletonDataFile(skelPath);

    if (!m_skeletonData) {
        qWarning() << "Failed to load skeleton data:" << binary.getError().buffer();
        return;
    }

    m_skeleton = new spine::Skeleton(m_skeletonData);
    m_animationStateData = new spine::AnimationStateData(m_skeletonData);
    m_animationState = new spine::AnimationState(m_animationStateData);

    if (!m_animation.isEmpty()) {
        setAnimation(m_animation);
    }
}

void SpineItem::updateAnimation() {
    if (!m_skeleton || !m_animationState) return;

    float dt = m_timer.restart() / 1000.0f;
    m_animationState->update(dt);
    m_animationState->apply(*m_skeleton);
    m_skeleton->updateWorldTransform();

    update();
}

void SpineItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    update();
}

QSGNode *SpineItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
    if (!m_skeleton) return oldNode;

    QSGTransformNode* rootNode = static_cast<QSGTransformNode*>(oldNode);
    if (!rootNode) {
        rootNode = new QSGTransformNode();
    } else {
        while (QSGNode *child = rootNode->firstChild()) {
            rootNode->removeChildNode(child);
            delete child;
        }
    }

    QMatrix4x4 matrix;
    matrix.translate(width() / 2.0, height() * 0.9);
    matrix.scale(1.0, -1.0);
    rootNode->setMatrix(matrix);

    auto& drawOrder = m_skeleton->getDrawOrder();
    for (size_t i = 0, n = drawOrder.size(); i < n; ++i) {
        spine::Slot* slot = drawOrder[i];
        spine::Attachment* attachment = slot->getAttachment();
        if (!attachment) continue;

        QImage* image = nullptr;
        spine::Vector<float> vertices;
        spine::Vector<float> uvs;
        spine::Vector<unsigned short> indices;

        if (attachment->getRTTI().isExactly(spine::RegionAttachment::rtti)) {
            spine::RegionAttachment* region = static_cast<spine::RegionAttachment*>(attachment);
            spine::AtlasRegion* atlasRegion = static_cast<spine::AtlasRegion*>(region->getRendererObject());
            image = static_cast<QImage*>(atlasRegion->page->getRendererObject());
            
            vertices.setSize(8, 0);
            region->computeWorldVertices(slot->getBone(), vertices.buffer(), 0, 2);
            
            uvs.clear();
            for (size_t v = 0; v < region->getUVs().size(); ++v) {
                uvs.add(region->getUVs()[v]);
            }
            
            indices.clear();
            indices.add(0); indices.add(1); indices.add(2);
            indices.add(2); indices.add(3); indices.add(0);
        } else if (attachment->getRTTI().isExactly(spine::MeshAttachment::rtti)) {
            spine::MeshAttachment* mesh = static_cast<spine::MeshAttachment*>(attachment);
            spine::AtlasRegion* atlasRegion = static_cast<spine::AtlasRegion*>(mesh->getRendererObject());
            image = static_cast<QImage*>(atlasRegion->page->getRendererObject());
            
            vertices.setSize(mesh->getWorldVerticesLength(), 0);
            mesh->computeWorldVertices(*slot, 0, mesh->getWorldVerticesLength(), vertices.buffer(), 0, 2);
            
            uvs.clear();
            for (size_t v = 0; v < mesh->getUVs().size(); ++v) {
                uvs.add(mesh->getUVs()[v]);
            }
            
            indices.clear();
            for (size_t v = 0; v < mesh->getTriangles().size(); ++v) {
                indices.add(mesh->getTriangles()[v]);
            }
        } else {
            continue;
        }

        if (!image || image->isNull()) continue;

        QSGGeometryNode* node = new QSGGeometryNode();
        QSGGeometry* geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), vertices.size() / 2, indices.size());
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);

        QSGGeometry::TexturedPoint2D* points = geometry->vertexDataAsTexturedPoint2D();
        for (size_t v = 0, pt = 0; v < vertices.size(); v += 2, ++pt) {
            points[pt].set(vertices[v], vertices[v + 1], uvs[v], uvs[v + 1]);
        }

        uint16_t* indexData = geometry->indexDataAsUShort();
        for (size_t ind = 0; ind < indices.size(); ++ind) {
            indexData[ind] = indices[ind];
        }

        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        QSGTexture* texture = m_textures.value(image, nullptr);
        if (!texture) {
            texture = window()->createTextureFromImage(*image);
            m_textures.insert(image, texture);
        }

        QSGTextureMaterial* material = new QSGTextureMaterial();
        material->setTexture(texture);
        material->setFlag(QSGMaterial::Blending, true); 
        
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);

        rootNode->appendChildNode(node);
    }

    return rootNode;
}